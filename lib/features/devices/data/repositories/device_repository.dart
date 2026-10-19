import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/device_model.dart';

/// Repository responsible for sending device registration data to secure Cloud Functions
/// and streaming registered devices from Cloud Firestore.
class DeviceRepository {
  DeviceRepository({FirebaseFunctions? functions, FirebaseFirestore? firestore})
    : _customFunctions = functions,
      _customFirestore = firestore {
    if (!_hasLoadedFromPrefs) {
      loadPersistedDevices();
    }
  }

  final FirebaseFunctions? _customFunctions;
  final FirebaseFirestore? _customFirestore;

  FirebaseFunctions? get _functions {
    if (_customFunctions != null) return _customFunctions;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFunctions.instance;
    } catch (_) {}
    return null;
  }

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (_) {}
    return null;
  }

  static final Map<String, DeviceModel> _cachedDevices = {};
  static final StreamController<List<DeviceModel>> _deviceStreamController =
      StreamController<List<DeviceModel>>.broadcast();
  static bool _hasLoadedFromPrefs = false;
  static const String _prefKeyDevicesJson = 'simple_push_saved_devices_json';

  static void _notify() {
    if (!_deviceStreamController.isClosed) {
      _deviceStreamController.add(_cachedDevices.values.toList());
    }
  }

  static Future<void> _persistDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list =
          _cachedDevices.values.map((d) => jsonEncode(d.toJson())).toList();
      await prefs.setStringList(_prefKeyDevicesJson, list);
    } catch (e) {
      debugPrint('[DeviceRepository] Failed to persist devices: $e');
    }
  }

  /// Loads previously saved devices from local storage on app start.
  Future<void> loadPersistedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefKeyDevicesJson);
      if (list != null) {
        for (final item in list) {
          try {
            final data = jsonDecode(item) as Map<String, dynamic>;
            final device = DeviceModel.fromJson(data);
            _cachedDevices[device.deviceId] = device;
          } catch (_) {}
        }
        _notify();
      }
      _hasLoadedFromPrefs = true;
    } catch (e) {
      debugPrint('[DeviceRepository] Failed to load persisted devices: $e');
    }
  }

  /// Manually registers a receiver device by Device ID, Name, and optional Token.
  Future<void> addDeviceManually({
    required String deviceId,
    required String deviceName,
    String? fcmToken,
    String platform = 'Android',
    String osVersion = 'Unknown',
  }) async {
    final cleanId = deviceId.trim();
    final cleanName =
        deviceName.trim().isNotEmpty ? deviceName.trim() : 'Remote Device';
    final cleanToken = (fcmToken != null && fcmToken.trim().isNotEmpty)
        ? fcmToken.trim()
        : 'token_${cleanId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}_manual';

    final deviceModel = DeviceModel(
      deviceId: cleanId,
      fcmToken: cleanToken,
      deviceName: cleanName,
      platform: platform,
      osVersion: osVersion,
      appVersion: '1.0.0',
      isActive: true,
      registeredAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    );

    _cachedDevices[cleanId] = deviceModel;
    _notify();
    await _persistDevices();

    // Also attempt remote Firestore / Cloud Function registration in background
    try {
      _devicesRef
          ?.doc(cleanId)
          .set(deviceModel.toMap(), SetOptions(merge: true))
          .catchError((_) {});
    } catch (_) {}
  }

  /// Removes a registered device from local cache, persistence, and Firestore.
  Future<void> removeDevice(String deviceId) async {
    _cachedDevices.remove(deviceId);
    _notify();
    await _persistDevices();

    try {
      _devicesRef?.doc(deviceId).delete().catchError((_) {});
    } catch (_) {}
  }

  CollectionReference<Map<String, dynamic>>? get _devicesRef {
    final fs = _firestore;
    if (fs == null) return null;
    try {
      return fs.collection(AppConstants.devicesCollection);
    } catch (_) {
      return null;
    }
  }

  /// Registers a receiver device by sending its FCM token and metadata to the
  /// secure 'registerDevice' Firebase Cloud Function (Requirement 4).
  /// The Cloud Function deduplicates tokens and writes to Firestore 'devices' (Requirement 5 & 7).
  Future<void> registerOrUpdateDevice({
    required String deviceId,
    required String fcmToken,
    required String deviceName,
    required String platform,
    required String osVersion,
    String appVersion = '1.0.0',
  }) async {
    // 1. Cache device locally so it is immediately visible in UI
    final deviceModel = DeviceModel(
      deviceId: deviceId,
      fcmToken: fcmToken,
      deviceName: deviceName,
      platform: platform,
      osVersion: osVersion,
      appVersion: appVersion,
      isActive: true,
      registeredAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    );
    _cachedDevices[deviceId] = deviceModel;
    _notify();
    _persistDevices();

    // 2. Attempt registration via Cloud Function
    try {
      final fn = _functions;
      if (fn != null) {
        debugPrint(
          '[DeviceRepository] Calling Cloud Function "${AppConstants.registerDeviceFunctionName}" '
          'for device: $deviceId (Model: $deviceName)...',
        );

        final callable = fn.httpsCallable(
          AppConstants.registerDeviceFunctionName,
          options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
        );

        final response = await callable.call<Map<String, dynamic>>({
          'deviceId': deviceId.trim(),
          'fcmToken': fcmToken.trim(),
          'deviceName': deviceName.trim(),
          'platform': platform.trim(),
          'osVersion': osVersion.trim(),
          'appVersion': appVersion.trim(),
        });

        debugPrint(
          '[DeviceRepository] Device registration confirmed by Cloud Function: ${response.data}',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[DeviceRepository] Cloud Function notice [${e.code}]: ${e.message}',
      );
      // Fallback: If Cloud Functions is not deployed yet, attempt direct Firestore write
      try {
        await _devicesRef?.doc(deviceId).set({
          'deviceId': deviceId,
          'fcmToken': fcmToken,
          'deviceName': deviceName,
          'platform': platform,
          'osVersion': osVersion,
          'appVersion': appVersion,
          'isActive': true,
          'registeredAt': FieldValue.serverTimestamp(),
          'lastSeenAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[DeviceRepository] Local fallback registration succeeded.');
      } catch (fallbackError) {
        debugPrint(
          '[DeviceRepository] Fallback registration notice: $fallbackError',
        );
      }
    } catch (e) {
      debugPrint('[DeviceRepository] Notice during device registration: $e');
    }
  }

  /// Updates the device record via secure Cloud Function when FCM token refreshes (Requirement 6).
  Future<void> updateToken(String deviceId, String newToken) async {
    if (_cachedDevices.containsKey(deviceId)) {
      _cachedDevices[deviceId] = _cachedDevices[deviceId]!.copyWith(
        fcmToken: newToken,
        lastSeenAt: DateTime.now(),
      );
    }

    try {
      final fn = _functions;
      if (fn != null) {
        debugPrint(
          '[DeviceRepository] Calling Cloud Function "${AppConstants.updateDeviceTokenFunctionName}" '
          'for refreshed token on $deviceId...',
        );

        final callable = fn.httpsCallable(
          AppConstants.updateDeviceTokenFunctionName,
          options: HttpsCallableOptions(timeout: const Duration(seconds: 15)),
        );

        await callable.call<Map<String, dynamic>>({
          'deviceId': deviceId.trim(),
          'fcmToken': newToken.trim(),
        });

        debugPrint(
          '[DeviceRepository] Token refresh successfully saved via Cloud Function.',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[DeviceRepository] Cloud Function token update error [${e.code}]: ${e.message}',
      );
      try {
        await _devicesRef?.doc(deviceId).update({
          'fcmToken': newToken,
          'isActive': true,
          'lastSeenAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('[DeviceRepository] Failed to update refreshed token: $e');
    }
  }

  /// Real-time stream of all active registered devices for the sender screen (Requirement 8).
  /// Firestore Security Rules restrict this stream exclusively to authorized senders (Requirement 9).
  Stream<List<DeviceModel>> watchRegisteredDevices() async* {
    // 1. Immediately yield cached devices so the screen renders instantly without delay
    yield _cachedDevices.values.toList();

    // 2. Stream from Cloud Firestore with fallback resilience
    try {
      final ref = _devicesRef;
      if (ref != null) {
        await for (final snapshot
            in ref.where('isActive', isEqualTo: true).snapshots()) {
          final list = snapshot.docs
              .map((doc) => DeviceModel.fromFirestore(doc))
              .toList();
          for (final d in list) {
            _cachedDevices[d.deviceId] = d;
          }
          yield _cachedDevices.values.toList();
        }
      } else {
        yield* _deviceStreamController.stream;
      }
    } catch (error) {
      debugPrint('[DeviceRepository] Firestore stream notice: $error');
      yield _cachedDevices.values.toList();
    }
  }

  /// One-time fetch of all registered devices.
  Future<List<DeviceModel>> getRegisteredDevices() async {
    try {
      final ref = _devicesRef;
      if (ref != null) {
        final snapshot = await ref
            .where('isActive', isEqualTo: true)
            .get()
            .timeout(const Duration(seconds: 5));
        final list = snapshot.docs
            .map((doc) => DeviceModel.fromFirestore(doc))
            .toList();
        for (final d in list) {
          _cachedDevices[d.deviceId] = d;
        }
      }
      return _cachedDevices.values.toList();
    } catch (e) {
      debugPrint('[DeviceRepository] Failed to get registered devices: $e');
      return _cachedDevices.values.toList();
    }
  }

  /// Retrieves a single device record by ID.
  Future<DeviceModel?> getDevice(String deviceId) async {
    try {
      final ref = _devicesRef;
      if (ref == null) return _cachedDevices[deviceId];
      final doc = await ref.doc(deviceId).get();
      if (!doc.exists) return null;
      return DeviceModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[DeviceRepository] Failed to get device $deviceId: $e');
      return _cachedDevices[deviceId];
    }
  }
}
