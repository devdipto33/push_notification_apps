import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/fcm_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'features/devices/data/repositories/device_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Mount UI immediately so the user NEVER sees a black screen
  runApp(const PushNotificationApp());

  // 2. Run all background services and Firebase setups asynchronously
  unawaited(_initializeApp());
}

Future<void> _initializeApp() async {
  // 1. Initialize local notification display plugin & channel
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('[Main] NotificationService init notice: $e');
  }

  // 2. Initialize Firebase Core & device identity
  try {
    await FirebaseService.instance.initialize();
  } catch (e) {
    debugPrint('[Main] FirebaseService init notice: $e');
  }

  // 3. Set up push notifications and device registration
  await _setupMessagingAndRegisterDevice();
}

/// Sets up push notification permissions, listeners, and registers this device in Firestore.
Future<void> _setupMessagingAndRegisterDevice() async {
  try {
    // 1. Request notification permissions (Android 13+ / iOS)
    await FcmService.instance.requestPermission();

    final deviceRepo = DeviceRepository();
    final deviceId = FirebaseService.instance.installationId;
    final deviceName = FirebaseService.instance.deviceName ?? 'Android Device';
    final platform = !kIsWeb && Platform.isIOS ? 'iOS' : 'Android';

    // 2. Initialize FCM listeners and token refresh callback
    await FcmService.instance.initialize(
      onTokenRefresh: (newToken) async {
        if (deviceId != null) {
          try {
            await deviceRepo.updateToken(deviceId, newToken);
          } catch (e) {
            debugPrint(
              '[Main] Error updating refreshed token in Firestore: $e',
            );
          }
        }
      },
      onNotificationOpened: (message) {
        debugPrint('[Main] Notification tapped by user: ${message.data}');
      },
    );

    // 3. Register current device in Firestore with its unique persistent installation ID
    final fcmToken = FcmService.instance.currentToken;

    // ==========================================================
    // ✅ ADDED: PRINT FCM TOKEN FOR FIREBASE CONSOLE TESTING
    // ==========================================================
    if (fcmToken != null && fcmToken.isNotEmpty) {
      debugPrint('========== FCM REGISTRATION TOKEN ==========');
      debugPrint(fcmToken);
      debugPrint('============================================');
    } else {
      debugPrint(
        '[Main] FCM token is not available yet. '
        'Check FcmService.initialize() and currentToken.',
      );
    }
    // ================= END OF ADDED CODE ======================

    if (deviceId != null && fcmToken != null && fcmToken.isNotEmpty) {
      await deviceRepo.registerOrUpdateDevice(
        deviceId: deviceId,
        fcmToken: fcmToken,
        deviceName: deviceName,
        platform: platform,
        osVersion: Platform.operatingSystemVersion,
      );
      debugPrint('[Main] Device registered successfully in Firestore.');
    }
  } catch (e, st) {
    debugPrint('[Main] Error during messaging setup / registration: $e\n$st');
  }
}