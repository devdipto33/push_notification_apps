import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'notification_service.dart';

/// Top-level background message entry-point.
/// Must be outside any class and marked with @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // If already initialized in this isolate or options not found, proceed
  }
  debugPrint(
    '[FCM Background Handler] Message ID: ${message.messageId} | '
    'Title: ${message.notification?.title ?? message.data['title']} | '
    'Body: ${message.notification?.body ?? message.data['body']}',
  );
}

/// Service that coordinates Firebase Cloud Messaging permissions, tokens,
/// foreground listeners, and interaction callbacks.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSubscription;

  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Requests notification permissions across iOS, Web, and Android 13+ (API 33+).
  Future<NotificationSettings> requestPermission() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      debugPrint(
        '[FcmService] Permission status: ${settings.authorizationStatus}',
      );
      return settings;
    } catch (e) {
      debugPrint('[FcmService] Failed to request permission: $e');
      rethrow;
    }
  }

  /// Obtains the current device registration token from FCM.
  Future<String?> getFcmToken() async {
    try {
      // ignore: deprecated_member_use
      _currentToken = await _fcm.getToken();
      debugPrint(
        // '[FcmService] FCM Token obtained: '
        // '${_currentToken != null && _currentToken!.length > 12 ? "${_currentToken!.substring(0, 12)}..." : _currentToken}',
        '[FcmService] FCM TOKEN: $_currentToken',
      );
      return _currentToken;
    } catch (e) {
      debugPrint('[FcmService] Error fetching FCM token: $e');
      return null;
    }
  }

  /// Sets up listeners for foreground push notifications, token refresh, and tap events.
  Future<void> initialize({
    required void Function(String newToken) onTokenRefresh,
    void Function(RemoteMessage message)? onNotificationOpened,
  }) async {
    // 1. Register top-level background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Fetch initial registration token
    await getFcmToken();

    // 3. Listen to token rotation
    _tokenRefreshSubscription?.cancel();
    // ignore: deprecated_member_use
    _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('[FcmService] FCM token refreshed.');
      _currentToken = newToken;
      onTokenRefresh(newToken);
    });

    // 4. Handle messages received while the app is in foreground
    _onMessageSubscription?.cancel();
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[FcmService] Foreground message received: ${message.messageId}',
      );
      _handleForegroundMessage(message);
    });

    // 5. Handle when a notification is clicked while the app is running in background
    _onMessageOpenedSubscription?.cancel();
    _onMessageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      debugPrint(
        '[FcmService] App opened from background notification: ${message.messageId}',
      );
      onNotificationOpened?.call(message);
    });

    // 6. Check if the app was launched directly from a terminated state notification tap
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '[FcmService] App launched from terminated state notification: ${initialMessage.messageId}',
      );
      onNotificationOpened?.call(initialMessage);
    }
  }

  /// Displays foreground notifications using local notification channel.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;

    if (title != null || body != null) {
      NotificationService.instance.showNotification(
        id: message.hashCode,
        title: title ?? 'New Message',
        body: body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Cancels all active FCM subscriptions.
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _onMessageSubscription?.cancel();
    _onMessageOpenedSubscription?.cancel();
  }
}
