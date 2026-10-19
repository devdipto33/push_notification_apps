import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../constants/app_constants.dart';

/// Central coordinator for Firebase core, authentication, and device identity.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _isFirebaseInitialized = false;
  bool get isFirebaseInitialized => _isFirebaseInitialized;

  String? _cachedInstallationId;
  String? get installationId => _cachedInstallationId;

  String? _cachedDeviceName;
  String? get deviceName => _cachedDeviceName;

  /// Initializes Firebase Core, authenticates anonymous sender session if enabled,
  /// and retrieves or generates a persistent device installation ID.
  Future<bool> initialize() async {
    // 1. Always resolve device identity immediately
    await _resolveDeviceIdentity();

    // 2. Initialize Firebase Core
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 4));
      }
      _isFirebaseInitialized = true;
      debugPrint('[FirebaseService] Firebase initialized successfully.');

      // Authenticate anonymously so caller has a valid Firebase Auth UID for Firestore rules
      await _ensureAuthenticated();

      return true;
    } catch (e, st) {
      debugPrint('[FirebaseService] Firebase initialization notice: $e\n$st');
      _isFirebaseInitialized = false;
      return false;
    }
  }

  /// Ensures an active Firebase Auth user session.
  /// Falls back to anonymous sign-in if no user is signed in.
  Future<User?> _ensureAuthenticated() async {
    try {
      final auth = FirebaseAuth.instance;
      User? user = auth.currentUser;
      if (user == null) {
        final credential = await auth
            .signInAnonymously()
            .timeout(const Duration(seconds: 3));
        user = credential.user;
        debugPrint(
          '[FirebaseService] Signed in anonymously with UID: ${user?.uid}',
        );
      }
      return user;
    } catch (e) {
      debugPrint(
        '[FirebaseService] Anonymous sign-in notice (check Firebase Auth config): $e',
      );
      return null;
    }
  }

  /// Retrieves or creates a permanent UUID-like installation ID stored in SharedPreferences.
  /// This ensures each physical app install has a stable device document ID in Firestore.
  Future<void> _resolveDeviceIdentity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(AppConstants.prefKeyDeviceId);

      if (id == null || id.isEmpty) {
        // Generate a stable installation identifier
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final randomPart = (timestamp ^ 0x5DEECE66D).toRadixString(16);
        id = 'dev_${timestamp}_$randomPart';
        await prefs.setString(AppConstants.prefKeyDeviceId, id);
      }
      _cachedInstallationId = id;

      // Resolve hardware model name via device_info_plus
      final deviceInfo = DeviceInfoPlugin();
      String name = 'Mobile Device';

      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final manufacturer = androidInfo.manufacturer;
        final model = androidInfo.model;
        name = '$manufacturer $model'.trim();
        if (name.isEmpty) name = 'Android Device';
      } else if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.utsname.machine.isNotEmpty
            ? iosInfo.utsname.machine
            : 'iOS Device';
      } else if (kIsWeb) {
        name = 'Web Browser';
      }

      _cachedDeviceName = name;
      await prefs.setString(AppConstants.prefKeyDeviceName, name);

      debugPrint('[FirebaseService] Device identified as: $name (ID: $id)');
    } catch (e) {
      debugPrint('[FirebaseService] Error resolving device identity: $e');
      _cachedInstallationId ??=
          'dev_fallback_${DateTime.now().millisecondsSinceEpoch}';
      _cachedDeviceName ??= 'Android Device';
    }
  }

  /// Checks if the current authenticated user is listed in authorized_senders collection.
  Future<bool> isCurrentSenderAuthorized() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.sendersCollection)
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data()?['isAuthorized'] == true) {
        return true;
      }

      // If document doesn't exist, check whether the project is in open development mode
      // or if any authorized sender exists. In development, auto-register the first user if collection is empty!
      final sendersCount = await FirebaseFirestore.instance
          .collection(AppConstants.sendersCollection)
          .limit(1)
          .get();

      if (sendersCount.docs.isEmpty) {
        // Auto-bootstrap the first user as authorized developer sender
        await FirebaseFirestore.instance
            .collection(AppConstants.sendersCollection)
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'email': user.email ?? 'dev_sender@local',
              'isAuthorized': true,
              'role': 'admin_sender',
              'createdAt': FieldValue.serverTimestamp(),
              'note': 'Auto-authorized first developer user.',
            });
        debugPrint(
          '[FirebaseService] Bootstrapped current user as authorized sender: ${user.uid}',
        );
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[FirebaseService] Sender authorization check error: $e');
      return false;
    }
  }
}
