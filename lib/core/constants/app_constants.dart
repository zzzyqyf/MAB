class AppConstants {
  // App Information
  static const String appName = 'PlantCare Hubs';
  static const String appVersion = '1.0.0';
  
  // Database Keys
  static const String deviceBoxKey = 'deviceBox';
  static const String notificationsBoxKey = 'notificationsBox';
  static const String graphDataBoxKey = 'graphdata';
  
  // Device Status
  static const String deviceStatusOnline = 'online';
  static const String deviceStatusOffline = 'offline';
  static const String deviceStatusConnecting = 'connecting';
  
  // Notification Settings
  static const String notificationChannelId = 'plant_care_notifications';
  static const String notificationChannelName = 'PlantCare Notifications';
  static const String notificationChannelDescription = 'Notifications for plant care updates';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration loadingAnimationDuration = Duration(milliseconds: 1500);
}
