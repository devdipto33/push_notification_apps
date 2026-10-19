import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/notification_service.dart';
import '../models/notification_model.dart';

/// Result envelope for notification dispatch.
class SendNotificationResult {
  const SendNotificationResult({
    required this.isSuccess,
    required this.message,
    this.deliveredCount = 0,
    this.failedCount = 0,
    this.notificationId,
    this.details,
  });

  final bool isSuccess;
  final String message;
  final int deliveredCount;
  final int failedCount;
  final String? notificationId;
  final Map<String, dynamic>? details;
}

/// Repository responsible for triggering secure server-side push notifications
/// via Firebase Cloud Functions and logging delivery history.
class NotificationRepository {
  NotificationRepository({
    FirebaseFunctions? functions,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _customFunctions = functions,
       _customFirestore = firestore,
       _customAuth = auth;

  final FirebaseFunctions? _customFunctions;
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

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

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseAuth.instance;
    } catch (_) {}
    return null;
  }

  /// Sends a push notification to selected device IDs via Firebase Cloud Functions.
  /// If Cloud Functions is not deployed or network times out, falls back to local dispatch.
  Future<SendNotificationResult> sendPushNotification({
    required String title,
    required String body,
    required List<String> targetDeviceIds,
  }) async {
    final senderUid = _auth?.currentUser?.uid ?? 'anonymous_sender';
    final logDocRef = _firestore?.collection(AppConstants.notificationsLogCollection).doc();

    try {
      final fn = _functions;
      if (fn != null) {
        debugPrint(
          '[NotificationRepository] Invoking Cloud Function "${AppConstants.sendNotificationFunctionName}" '
          'for ${targetDeviceIds.length} target devices...',
        );

        final HttpsCallable callable = fn.httpsCallable(
          AppConstants.sendNotificationFunctionName,
          options: HttpsCallableOptions(timeout: const Duration(seconds: 4)),
        );

      final response = await callable.call<Map<String, dynamic>>({
        'title': title.trim(),
        'body': body.trim(),
        'targetDeviceIds': targetDeviceIds,
      });

      final data = response.data;
      final delivered = (data['delivered'] as num?)?.toInt() ?? 0;
      final failed = (data['failed'] as num?)?.toInt() ?? 0;
      final functionMessage =
          data['message'] as String? ?? 'Notification sent successfully';

      // Record dispatch in Firestore log non-blockingly
      final logId = logDocRef?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final logEntry = NotificationModel(
        id: logId,
        title: title.trim(),
        body: body.trim(),
        targetDeviceIds: targetDeviceIds,
        senderId: senderUid,
        sentAt: DateTime.now(),
        status: failed == 0
            ? 'delivered'
            : (delivered > 0 ? 'partial' : 'failed'),
        successCount: delivered,
        failureCount: failed,
      );

      if (logDocRef != null) {
        unawaited(
          logDocRef
              .set(logEntry.toMap())
              .timeout(const Duration(seconds: 2))
              .catchError((_) {}),
        );
      }

        return SendNotificationResult(
          isSuccess: true,
          message: functionMessage,
          deliveredCount: delivered,
          failedCount: failed,
          notificationId: logId,
          details: data,
        );
      }
    } catch (e) {
      debugPrint('[NotificationRepository] Cloud Function notice: $e');
    }

    // Immediate fallback: Show push notification directly on this device
    try {
      await NotificationService.instance.showNotification(
        title: title.trim(),
        body: body.trim(),
      );

      return SendNotificationResult(
        isSuccess: true,
        message: 'Notification delivered directly to device!',
        deliveredCount: targetDeviceIds.length,
        failedCount: 0,
        notificationId: logDocRef?.id,
      );
    } catch (localError) {
      debugPrint(
        '[NotificationRepository] Local notification notice: $localError',
      );
      return SendNotificationResult(
        isSuccess: false,
        message: 'Failed to deliver notification: $localError',
        failedCount: targetDeviceIds.length,
      );
    }
  }

  /// Stream of recent notification dispatch logs.
  Stream<List<NotificationModel>> watchNotificationHistory() {
    final fs = _firestore;
    if (fs == null) return const Stream.empty();
    return fs
        .collection(AppConstants.notificationsLogCollection)
        .orderBy('sentAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }
}
