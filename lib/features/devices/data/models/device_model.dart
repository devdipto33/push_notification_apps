import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a registered client device capable of receiving push notifications.
class DeviceModel {
  const DeviceModel({
    required this.deviceId,
    required this.fcmToken,
    required this.deviceName,
    required this.platform,
    this.osVersion = 'Unknown',
    this.appVersion = '1.0.0',
    this.isActive = true,
    required this.registeredAt,
    required this.lastSeenAt,
  });

  /// Unique permanent identifier stored in local SharedPreferences for this installation.
  /// Not the FCM token, because FCM tokens can rotate.
  final String deviceId;

  /// Current FCM push registration token.
  final String fcmToken;

  /// Human-readable device model (e.g., "Google Pixel 8", "Samsung Galaxy S23").
  final String deviceName;

  /// Target operating system (e.g., "Android", "iOS").
  final String platform;

  /// OS release version (e.g., "14", "13").
  final String osVersion;

  /// App build version.
  final String appVersion;

  /// Registration / active status.
  final bool isActive;

  /// Timestamp when the device was first registered.
  final DateTime registeredAt;

  /// Timestamp of the last token refresh or app launch.
  final DateTime lastSeenAt;

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'fcmToken': fcmToken,
      'deviceName': deviceName,
      'platform': platform,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'isActive': isActive,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'lastSeenAt': Timestamp.fromDate(lastSeenAt),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'fcmToken': fcmToken,
      'deviceName': deviceName,
      'platform': platform,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'isActive': isActive,
      'registeredAt': registeredAt.toIso8601String(),
      'lastSeenAt': lastSeenAt.toIso8601String(),
    };
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel.fromMap(json, json['deviceId'] as String? ?? '');
  }

  factory DeviceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DeviceModel.fromMap(data, doc.id);
  }

  factory DeviceModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return DeviceModel(
      deviceId: data['deviceId'] as String? ?? id,
      fcmToken: data['fcmToken'] as String? ?? '',
      deviceName: data['deviceName'] as String? ?? 'Unknown Device',
      platform: data['platform'] as String? ?? 'Android',
      osVersion: data['osVersion'] as String? ?? 'Unknown',
      appVersion: data['appVersion'] as String? ?? '1.0.0',
      isActive: data['isActive'] as bool? ?? true,
      registeredAt: parseDate(data['registeredAt']),
      lastSeenAt: parseDate(data['lastSeenAt']),
    );
  }

  DeviceModel copyWith({
    String? deviceId,
    String? fcmToken,
    String? deviceName,
    String? platform,
    String? osVersion,
    String? appVersion,
    bool? isActive,
    DateTime? registeredAt,
    DateTime? lastSeenAt,
  }) {
    return DeviceModel(
      deviceId: deviceId ?? this.deviceId,
      fcmToken: fcmToken ?? this.fcmToken,
      deviceName: deviceName ?? this.deviceName,
      platform: platform ?? this.platform,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      isActive: isActive ?? this.isActive,
      registeredAt: registeredAt ?? this.registeredAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
