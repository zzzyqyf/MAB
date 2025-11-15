import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import 'alarm_service.dart';
import '../widgets/snooze_picker_dialog.dart';

/// Global function required for background message handling
/// Must be top-level function to work with background isolate
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [FCM Background] Handling background message: ${message.messageId}');
  debugPrint('📦 [FCM Background] Data: ${message.data}');
  
  // Background handler is called when app is terminated
  // We'll use local notifications to alert the user and trigger alarm when they tap
  if (message.data.containsKey('alarmType')) {
    debugPrint('🚨 [FCM Background] Alarm message received in background');
    // The notification will be shown by Firebase automatically
    // When user taps, app will open and foreground handler will play alarm
  }
}

/// Firebase Cloud Messaging service for handling push notifications
/// 
/// Responsibilities:
/// - Request notification permissions
/// - Get and save FCM token to Firestore
/// - Handle foreground messages (trigger alarm)
/// - Handle background messages (show notification)
/// - Handle notification taps (open app and trigger alarm)
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AlarmService _alarmService = AlarmService();
  
  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  BuildContext? _context; // Store context for showing dialogs
  
  String? get fcmToken => _fcmToken;

  /// Initialize FCM service
  /// Call this in main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    try {
      debugPrint('📱 [FCM] Initializing FCM service...');
      
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize local notifications for Android
      await _initializeLocalNotifications();
      
      // Get FCM token
      await _getFcmToken();
      
      // Setup message handlers
      _setupMessageHandlers();
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
      
      debugPrint('✅ [FCM] FCM service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [FCM] Failed to initialize FCM: $e');
      debugPrint('📚 Stack trace: $stackTrace');
    }
  }

  /// Request notification permissions (iOS requires explicit request, Android auto-granted)
  Future<void> _requestPermissions() async {
    debugPrint('🔐 [FCM] Requesting notification permissions...');
    
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true, // For critical alarms
      provisional: false,
      sound: true,
    );

    debugPrint('📋 [FCM] Permission status: ${settings.authorizationStatus}');
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ [FCM] Notification permissions granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('⚠️ [FCM] Provisional permission granted');
    } else {
      debugPrint('❌ [FCM] Notification permissions denied');
    }
  }

  /// Initialize local notifications for displaying custom notifications
  Future<void> _initializeLocalNotifications() async {
    debugPrint('🔔 [FCM] Initializing local notifications...');
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channel for alarms (Android)
    const androidChannel = AndroidNotificationChannel(
      'channel_id_5', // id - using high priority channel
      'Alarm Notifications High Priority', // name
      description: 'Critical sensor alarm notifications with maximum priority',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('beep'), // assets/sounds/beep.mp3
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    
    debugPrint('✅ [FCM] Local notifications initialized');
  }

  /// Get FCM token and save to Firestore
  Future<void> _getFcmToken() async {
    try {
      debugPrint('🎫 [FCM] Getting FCM token...');
      
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null) {
        debugPrint('✅ [FCM] FCM token received: ${_fcmToken!.substring(0, 20)}...');
        await _saveFcmTokenToFirestore();
      } else {
        debugPrint('⚠️ [FCM] Failed to get FCM token');
      }
    } catch (e) {
      debugPrint('❌ [FCM] Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore user document
  Future<void> _saveFcmTokenToFirestore() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('⚠️ [FCM] No user logged in, cannot save FCM token');
        return;
      }

      debugPrint('💾 [FCM] Saving FCM token to Firestore for user: $userId');
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
            'fcmToken': _fcmToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      debugPrint('✅ [FCM] FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ [FCM] Error saving FCM token to Firestore: $e');
    }
  }

  /// Handle FCM token refresh
  Future<void> _onTokenRefresh(String token) async {
    debugPrint('🔄 [FCM] Token refreshed: ${token.substring(0, 20)}...');
    _fcmToken = token;
    await _saveFcmTokenToFirestore();
  }

  /// Setup message handlers for foreground and background
  void _setupMessageHandlers() {
    debugPrint('📬 [FCM] Setting up message handlers...');
    
    // Foreground messages
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Handle notification tap when app was terminated
    _checkInitialMessage();
    
    debugPrint('✅ [FCM] Message handlers setup complete');
  }

  /// Handle messages when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('🔔 [FCM Foreground] Message received: ${message.messageId}');
    debugPrint('📋 [FCM Foreground] Title: ${message.notification?.title}');
    debugPrint('📝 [FCM Foreground] Body: ${message.notification?.body}');
    debugPrint('📦 [FCM Foreground] Data: ${message.data}');
    
    if (message.data.containsKey('alarmType')) {
      await _processAlarmMessage(message.data);
    }
    
    // Show local notification for foreground messages
    await _showLocalNotification(message);
  }

  /// Handle notification tap (app in background or terminated)
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint('👆 [FCM] Notification tapped: ${message.messageId}');
    debugPrint('📦 [FCM] Data: ${message.data}');
    
    if (message.data.containsKey('alarmType')) {
      await _processAlarmMessage(message.data);
    }
  }

  /// Check if app was opened from notification while terminated
  Future<void> _checkInitialMessage() async {
    final message = await _firebaseMessaging.getInitialMessage();
    if (message != null) {
      debugPrint('🚀 [FCM] App opened from notification (terminated state)');
      await _handleNotificationTap(message);
    }
  }

  /// Process alarm message and trigger alarm sound
  Future<void> _processAlarmMessage(Map<String, dynamic> data) async {
    debugPrint('🚨 [FCM] Processing alarm message...');
    
    try {
      final deviceId = data['deviceId'] as String?;
      final deviceName = data['deviceName'] as String?;
      final alarmType = data['alarmType'] as String?;
      final humidity = data['humidity'] as String?;
      final temperature = data['temperature'] as String?;
      final water = data['water'] as String?;
      
      if (deviceName == null || alarmType == null) {
        debugPrint('⚠️ [FCM] Missing required alarm data');
        return;
      }
      
      // Build alarm reason message
      String reason = '$deviceName: ';
      final List<String> issues = [];
      
      if (alarmType.contains('humidity') && humidity != null) {
        issues.add('Humidity $humidity%');
      }
      if (alarmType.contains('temperature') && temperature != null) {
        issues.add('Temperature $temperature°C');
      }
      if (alarmType.contains('water') && water != null) {
        issues.add('Water level $water%');
      }
      
      reason += issues.join(', ');
      
      debugPrint('🔊 [FCM] Starting alarm: $reason');
      debugPrint('🆔 [FCM] Device ID: $deviceId');
      
      // Save notification to Hive for notifications page
      try {
        final notificationsBox = Hive.box('notificationsBox');
        await notificationsBox.add({
          'title': '🚨 Sensor Alert',
          'message': reason,
          'timestamp': DateTime.now().toIso8601String(),
          'deviceId': deviceId,
          'deviceName': deviceName,
          'alarmType': alarmType,
          'read': false,
        });
        debugPrint('✅ [FCM] Notification saved to history');
      } catch (e) {
        debugPrint('⚠️ [FCM] Failed to save notification to Hive: $e');
      }
      
      // Trigger alarm sound with device information
      await _alarmService.startAlarm(
        reason,
        deviceId: deviceId,
        deviceName: deviceName,
      );
      
    } catch (e) {
      debugPrint('❌ [FCM] Error processing alarm message: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      
      if (notification == null) return;
      
      final androidDetails = AndroidNotificationDetails(
        'channel_id_5', // Using same channel ID as created above
        'Alarm Notifications High Priority',
        channelDescription: 'Critical sensor alarm notifications with maximum priority',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        color: Colors.red,
        sound: const RawResourceAndroidNotificationSound('beep'),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'dismiss',
            'Dismiss',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            'snooze',
            'Remind me later',
            showsUserInterface: true,
          ),
        ],
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'beep.mp3',
        interruptionLevel: InterruptionLevel.critical,
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
        notification.title,
        notification.body,
        details,
        payload: message.data.toString(),
      );
      
      debugPrint('✅ [FCM] Local notification shown');
    } catch (e) {
      debugPrint('❌ [FCM] Error showing local notification: $e');
    }
  }

  /// Handle notification action tap (Dismiss, Snooze)
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    debugPrint('👆 [FCM] Notification action: ${response.actionId}');
    
    switch (response.actionId) {
      case 'dismiss':
        await _dismissAlarm();
        break;
      case 'snooze':
        await _handleSnoozeRequest();
        break;
      default:
        // Notification body tapped, open app
        debugPrint('📱 [FCM] Notification body tapped');
        break;
    }
  }

  /// Handle snooze request - show picker and schedule reminder
  Future<void> _handleSnoozeRequest() async {
    try {
      debugPrint('⏰ [FCM] Snooze requested');
      
      // Get device information
      final deviceId = _alarmService.currentDeviceId;
      final deviceName = _alarmService.currentDeviceName;
      
      if (deviceId == null || deviceName == null) {
        debugPrint('⚠️ [FCM] No device info for snooze');
        await _alarmService.stopAlarm();
        return;
      }
      
      // Show snooze picker if we have context
      Duration? snoozeDuration;
      if (_context != null && _context!.mounted) {
        snoozeDuration = await SnoozePickerDialog.show(_context!);
      }
      
      // If no duration selected (cancelled or no context), use default 15 minutes
      snoozeDuration ??= const Duration(minutes: 15);
      
      debugPrint('⏰ [FCM] Snooze duration selected: ${snoozeDuration.inMinutes} minutes');
      
      // Calculate snooze until time
      final snoozeUntil = DateTime.now().add(snoozeDuration);
      
      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId != null) {
        // Update alarm state in user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'alarmState.$deviceId.snoozeUntil': Timestamp.fromDate(snoozeUntil),
          'alarmState.$deviceId.alarmActive': false, // Temporarily disable alarm
          'alarmState.$deviceId.snoozedAt': FieldValue.serverTimestamp(),
        });
        
        debugPrint('✅ [FCM] Firestore updated: snooze until $snoozeUntil');
      } else {
        debugPrint('⚠️ [FCM] No user ID, skipping Firestore update');
      }
      
      // Stop current alarm
      await _alarmService.stopAlarm();
      
      // Schedule reminder notification
      await _scheduleSnoozeReminder(
        deviceId: deviceId,
        deviceName: deviceName,
        snoozeUntil: snoozeUntil,
      );
      
      debugPrint('✅ [FCM] Snooze scheduled successfully');
      
    } catch (e) {
      debugPrint('❌ [FCM] Error handling snooze: $e');
      // Still stop alarm even if snooze fails
      await _alarmService.stopAlarm();
    }
  }

  /// Schedule a local notification reminder after snooze period
  Future<void> _scheduleSnoozeReminder({
    required String deviceId,
    required String deviceName,
    required DateTime snoozeUntil,
  }) async {
    try {
      debugPrint('� [FCM] Scheduling reminder for $snoozeUntil');
      
      final androidDetails = AndroidNotificationDetails(
        'channel_id_5', // Using same channel ID
        'Alarm Notifications High Priority',
        channelDescription: 'Critical sensor alarm notifications with maximum priority',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        sound: const RawResourceAndroidNotificationSound('beep'),
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'beep.mp3',
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Schedule notification
      await _localNotifications.zonedSchedule(
        deviceId.hashCode, // Unique ID based on device ID
        '⏰ Snooze Reminder: $deviceName',
        'Alarm snooze period ended. Tap to check sensor status.',
        tz.TZDateTime.from(snoozeUntil, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: deviceId, // Pass device ID for re-checking
      );
      
      debugPrint('✅ [FCM] Reminder scheduled');
      
    } catch (e) {
      debugPrint('❌ [FCM] Error scheduling reminder: $e');
    }
  }

  /// Set context for showing dialogs
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Dismiss alarm and update Firestore
  Future<void> _dismissAlarm() async {
    try {
      debugPrint('🔇 [FCM] Dismissing alarm...');
      
      // Get device ID from alarm service (this is the MQTT ID)
      final deviceId = _alarmService.currentDeviceId;
      
      if (deviceId != null) {
        // Get current user ID
        final userId = FirebaseAuth.instance.currentUser?.uid;
        
        if (userId != null) {
          // Update alarm state in user document
          debugPrint('💾 [FCM] Updating alarm state for user: $userId, device: $deviceId');
          
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .update({
            'alarmState.$deviceId.alarmActive': false,
            'alarmState.$deviceId.alarmAcknowledged': true,
            'alarmState.$deviceId.acknowledgedAt': FieldValue.serverTimestamp(),
          });
          
          debugPrint('✅ [FCM] Firestore updated: alarm acknowledged');
        } else {
          debugPrint('⚠️ [FCM] No user ID, skipping Firestore update');
        }
      } else {
        debugPrint('⚠️ [FCM] No device ID available, skipping Firestore update');
      }
      
      // Stop alarm sound locally
      await _alarmService.stopAlarm();
      
      debugPrint('✅ [FCM] Alarm dismissed');
    } catch (e) {
      debugPrint('❌ [FCM] Error dismissing alarm: $e');
      // Still stop alarm locally even if Firestore update fails
      await _alarmService.stopAlarm();
    }
  }

  /// Dispose of the service
  void dispose() {
    _foregroundSubscription?.cancel();
    _alarmService.dispose();
  }
}
