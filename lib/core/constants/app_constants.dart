/// Global application constants.
abstract final class AppConstants {
  static const String appName = 'Simple Push';
  static const String appTagline = 'Clean & Secure Firebase Push Messaging';

  // Firestore Collections
  static const String devicesCollection = 'devices';
  static const String sendersCollection = 'authorized_senders';
  static const String notificationsLogCollection = 'notifications_log';

  // Cloud Functions
  static const String registerDeviceFunctionName = 'registerDevice';
  static const String updateDeviceTokenFunctionName = 'updateDeviceToken';
  static const String sendNotificationFunctionName = 'sendPushNotification';

  // FCM Android Channel Configuration
  static const String notificationChannelId = 'simple_push_channel';
  static const String notificationChannelName = 'Simple Push Notifications';
  static const String notificationChannelDescription =
      'Receives priority direct push notification messages.';

  // SharedPreferences Keys
  static const String prefKeyDeviceId = 'simple_push_device_id';
  static const String prefKeyDeviceName = 'simple_push_device_name';

  // Validation Limits
  static const int minTitleLength = 3;
  static const int maxTitleLength = 80;
  static const int minBodyLength = 5;
  static const int maxBodyLength = 500;
}
