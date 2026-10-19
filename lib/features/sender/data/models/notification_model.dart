import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a push notification payload and delivery record.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.targetDeviceIds,
    this.senderId = 'anonymous_sender',
    required this.sentAt,
    this.status = 'sent',
    this.successCount = 0,
    this.failureCount = 0,
    this.errorMessage,
  });

  final String id;
  final String title;
  final String body;
  final List<String> targetDeviceIds;
  final String senderId;
  final DateTime sentAt;
  final String status;
  final int successCount;
  final int failureCount;
  final String? errorMessage;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'targetDeviceIds': targetDeviceIds,
      'senderId': senderId,
      'sentAt': Timestamp.fromDate(sentAt),
      'status': status,
      'successCount': successCount,
      'failureCount': failureCount,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return NotificationModel.fromMap(data, doc.id);
  }

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final targetList = data['targetDeviceIds'];
    List<String> devices = [];
    if (targetList is List) {
      devices = targetList.map((e) => e.toString()).toList();
    }

    return NotificationModel(
      id: data['id'] as String? ?? id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      targetDeviceIds: devices,
      senderId: data['senderId'] as String? ?? 'unknown',
      sentAt: parseDate(data['sentAt']),
      status: data['status'] as String? ?? 'sent',
      successCount: (data['successCount'] as num?)?.toInt() ?? 0,
      failureCount: (data['failureCount'] as num?)?.toInt() ?? 0,
      errorMessage: data['errorMessage'] as String?,
    );
  }
}
