import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage alarm sounds for urgent sensor conditions
/// 
/// Features:
/// - Continuous beeping alarm every 2 seconds when urgent conditions detected
/// - Text-to-Speech announcement of the alarm reason
/// - Visual alert banner on the overview page
/// - Manual mute option
/// 
/// Urgent Conditions:
/// - Humidity outside of mode range (80-85% Normal, 90-95% Pinning)
/// - Temperature above 30°C
/// - Water level below 30%
/// 
/// Usage:
/// The alarm is automatically triggered when viewing a device's overview page
/// if any sensor readings are in critical/urgent state (red status).
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal() {
    _initAudioPlayer();
  }

  static const MethodChannel _channel = MethodChannel('alarm_channel');
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  Timer? _beepTimer;
  bool _isAlarmActive = false;
  String? _currentAlarmReason;
  String? _currentDeviceId;
  String? _currentDeviceName;
  String? _firestoreNotificationId; // Track Firestore notification ID
  Timer? _snoozeTimer;

  bool get isAlarmActive => _isAlarmActive;
  String? get currentAlarmReason => _currentAlarmReason;
  String? get currentDeviceId => _currentDeviceId;
  String? get currentDeviceName => _currentDeviceName;

  /// Initialize audio player with alarm settings
  Future<void> _initAudioPlayer() async {
    try {
      debugPrint('🔊 Initializing AudioPlayer...');
      
      // Set audio player to use ALARM audio context (highest priority)
      await _audioPlayer.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm, // 使用 ALARM 音频类型
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      
      // Set volume to maximum
      await _audioPlayer.setVolume(1.0);
      
      // Set release mode to stop (don't loop)
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      debugPrint('✅ AudioPlayer initialized with ALARM audio context');
      
      // Test play a silent sound to "wake up" the audio system
      try {
        debugPrint('🔊 Testing audio system with silent playback...');
        await _audioPlayer.setVolume(0.01); // Very low volume
        await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
        await Future.delayed(const Duration(milliseconds: 100));
        await _audioPlayer.stop();
        await _audioPlayer.setVolume(1.0); // Restore full volume
        debugPrint('✅ Audio system test complete');
      } catch (testError) {
        debugPrint('⚠️ Audio test failed (non-critical): $testError');
      }
      
    } catch (e) {
      debugPrint('⚠️ Failed to initialize AudioPlayer: $e');
    }
  }

  /// Start the alarm with continuous beeping
  /// 
  /// [reason] - Human-readable alarm reason (e.g., "Mushroom Tent A: Humidity 75%, Temperature 31°C")
  /// [deviceId] - Firebase device ID for Firestore updates
  /// [deviceName] - Device display name
  Future<void> startAlarm(String reason, {String? deviceId, String? deviceName}) async {
    if (_isAlarmActive) return; // Already active
    
    _isAlarmActive = true;
    _currentAlarmReason = reason;
    _currentDeviceId = deviceId;
    _currentDeviceName = deviceName;
    
    debugPrint('🚨 ALARM STARTED: $reason');
    debugPrint('🆔 Device ID: $deviceId');
    debugPrint('📱 Platform: ${defaultTargetPlatform.toString()}');
    debugPrint('🔊 Starting alarm audio system...');
    
    // Save alarm to Firestore (first trigger only)
    await _saveAlarmToFirestore(reason, deviceId: deviceId, deviceName: deviceName);
    
    // Show persistent notification
    await _showPersistentNotification(reason, deviceId: deviceId, deviceName: deviceName);
    
    // Announce the alarm reason once
    try {
      await _tts.speak('Urgent Alert: $reason');
      debugPrint('🗣️ TTS announcement sent');
    } catch (e) {
      debugPrint('❌ TTS failed: $e');
    }
    
    // Start continuous beeping every 2 seconds
    _beepTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      debugPrint('🔔 Timer tick - playing beep...');
      await _playBeep();
    });
    
    // Play first beep immediately
    debugPrint('🔔 Playing first beep immediately...');
    await _playBeep();
  }

  /// Stop the alarm
  Future<void> stopAlarm() async {
    if (!_isAlarmActive) return;
    
    debugPrint('🔇 ALARM STOPPED');
    
    _beepTimer?.cancel();
    _beepTimer = null;
    _snoozeTimer?.cancel();
    _snoozeTimer = null;
    _isAlarmActive = false;
    _currentAlarmReason = null;
    _currentDeviceId = null;
    _currentDeviceName = null;
    
    // Cancel persistent notification
    await _cancelPersistentNotification();
    
    // Announce alarm stopped
    await _tts.speak('Alert cleared');
  }

  /// Dismiss alarm and save to Firestore
  Future<void> dismissAlarm() async {
    debugPrint('✋ User dismissed alarm');
    
    // Update Firestore notification status
    await _updateFirestoreNotification('dismissed');
    
    // Stop the alarm
    await stopAlarm();
  }

  /// Snooze alarm for specified duration
  Future<void> snoozeAlarm(Duration duration) async {
    debugPrint('⏰ Snoozing alarm for ${duration.inMinutes} minutes');
    
    // Update Firestore notification status
    await _updateFirestoreNotification('snoozed', snoozedUntil: DateTime.now().add(duration));
    
    // Stop beeping temporarily
    _beepTimer?.cancel();
    _beepTimer = null;
    
    // Cancel notification temporarily
    await _cancelPersistentNotification();
    
    // Announce snooze
    await _tts.speak('Alarm snoozed for ${duration.inMinutes} minutes');
    
    // Set timer to re-check after snooze duration
    _snoozeTimer = Timer(duration, () async {
      debugPrint('⏰ Snooze period ended, re-checking sensor conditions...');
      // Note: The sensor check will be triggered by the existing MQTT listener
      // If conditions still critical, alarm will restart via checkSensorAlarm()
    });
  }

  /// Play a single beep sound
  Future<void> _playBeep() async {
    debugPrint('🔊 _playBeep() called');
    
    try {
      // Method 1: Play audio file using audioplayers (PRIMARY METHOD)
      debugPrint('🎵 Playing beep.mp3 using audioplayers...');
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
      debugPrint('✅ Audio file played successfully via audioplayers');
      
      // ALSO try platform channel simultaneously for better reliability
      debugPrint('📞 Also invoking platform channel as backup...');
      try {
        final result = await _channel.invokeMethod('playBeep');
        debugPrint('✅ Platform channel also succeeded: $result');
      } catch (platformError) {
        debugPrint('⚠️ Platform channel failed but audioplayers worked: $platformError');
      }
      
      // Also add vibration for physical feedback
      debugPrint('📳 Triggering haptic feedback...');
      HapticFeedback.heavyImpact();
      
    } catch (audioError) {
      debugPrint('❌ Audio playback FAILED: $audioError');
      debugPrint('🔄 Trying fallback methods...');
      
      // Fallback 1: Try platform channel (Android ToneGenerator)
      try {
        debugPrint('📞 Invoking platform channel "playBeep"...');
        final result = await _channel.invokeMethod('playBeep');
        debugPrint('✅ Platform channel returned: $result');
        
        // Check volume level if returned
        if (result is Map) {
          final volume = result['volume'] as int?;
          final maxVolume = result['maxVolume'] as int?;
          debugPrint('🔊 Volume info - Current: $volume, Max: $maxVolume');
          
          if (volume != null && maxVolume != null) {
            if (volume == 0) {
              debugPrint('❌ CRITICAL: Alarm volume is MUTED (0/$maxVolume)!');
              debugPrint('📱 USER ACTION NEEDED: Please turn up alarm volume on your phone!');
              // Try to notify user via TTS
              await _tts.speak('Warning: Alarm volume is muted. Please turn up alarm volume.');
            } else if (volume < maxVolume ~/ 4) {
              debugPrint('⚠️ WARNING: Alarm volume is very low ($volume/$maxVolume). User may not hear the alarm!');
            } else {
              debugPrint('✅ Alarm volume OK: $volume/$maxVolume');
            }
          }
        } else {
          debugPrint('ℹ️ No volume info returned from platform');
        }
        
        // Also trigger haptic for physical feedback
        debugPrint('📳 Triggering haptic feedback...');
        HapticFeedback.heavyImpact();
        
      } catch (platformError, stackTrace) {
        // Fallback 2: Use haptic feedback only
        debugPrint('❌ Platform beep also FAILED: $platformError');
        debugPrint('📚 Stack trace: $stackTrace');
        debugPrint('🔄 Using final fallback: haptic feedback only');
        
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        HapticFeedback.heavyImpact();
        
        debugPrint('📳 Fallback haptic complete');
      }
    }
  }

  /// Check sensor data and start/stop alarm based on urgent conditions
  Future<void> checkSensorAlarm({
    required Map<String, dynamic> sensorData,
    required String deviceName,
    required Color humidityStatus,
    required Color temperatureStatus,
    required Color waterStatus,
  }) async {
    final List<String> urgentReasons = [];

    // Check each sensor for urgent status (red color = urgent)
    if (humidityStatus == Colors.red) {
      final humidity = sensorData['humidity'];
      urgentReasons.add('Humidity is critical: ${humidity ?? '--'}%');
    }

    if (temperatureStatus == Colors.red) {
      final temp = sensorData['temperature'];
      urgentReasons.add('Temperature is critical: ${temp ?? '--'}°C');
    }

    if (waterStatus == Colors.red) {
      final water = sensorData['moisture'];
      urgentReasons.add('Water level is critical: ${water ?? '--'}%');
    }

    // Start or stop alarm based on conditions
    if (urgentReasons.isNotEmpty) {
      final reason = '$deviceName: ${urgentReasons.join(', ')}';
      if (!_isAlarmActive || _currentAlarmReason != reason) {
        await startAlarm(reason);
      }
    } else {
      if (_isAlarmActive) {
        await stopAlarm();
      }
    }
  }

  /// Save alarm notification to Firestore (first trigger only)
  Future<void> _saveAlarmToFirestore(String reason, {String? deviceId, String? deviceName}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('⚠️ No user logged in, skipping Firestore save');
        return;
      }

      debugPrint('💾 Saving alarm notification to Firestore...');
      
      final notificationData = {
        'deviceId': deviceId ?? 'unknown',
        'deviceName': deviceName ?? 'Unknown Device',
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        'dismissedAt': null,
        'snoozedUntil': null,
        'type': 'urgent_alert',
      };

      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notificationData);

      _firestoreNotificationId = docRef.id;
      debugPrint('✅ Alarm notification saved to Firestore with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('❌ Failed to save alarm to Firestore: $e');
    }
  }

  /// Update Firestore notification status
  Future<void> _updateFirestoreNotification(String status, {DateTime? snoozedUntil}) async {
    try {
      if (_firestoreNotificationId == null) {
        debugPrint('⚠️ No Firestore notification ID to update');
        return;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      debugPrint('📝 Updating Firestore notification status to: $status');

      final updateData = <String, dynamic>{
        'status': status,
      };

      if (status == 'dismissed') {
        updateData['dismissedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'snoozed' && snoozedUntil != null) {
        updateData['snoozedUntil'] = Timestamp.fromDate(snoozedUntil);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(_firestoreNotificationId)
          .update(updateData);

      debugPrint('✅ Firestore notification updated');
    } catch (e) {
      debugPrint('❌ Failed to update Firestore notification: $e');
    }
  }

  /// Show persistent notification
  Future<void> _showPersistentNotification(String reason, {String? deviceId, String? deviceName}) async {
    try {
      debugPrint('🔔 Showing persistent notification...');

      const androidDetails = AndroidNotificationDetails(
        'urgent_alerts',
        'Urgent Alerts',
        channelDescription: 'Critical sensor condition alerts',
        importance: Importance.max,
        priority: Priority.max,
        ongoing: true, // Makes notification persistent
        autoCancel: false, // Prevent swipe to dismiss
        playSound: false, // We handle sound separately
        enableVibration: false, // We handle vibration separately
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'dismiss',
            'Dismiss',
            cancelNotification: false,
          ),
          AndroidNotificationAction(
            'snooze',
            'Snooze',
            cancelNotification: false,
          ),
        ],
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        999, // Fixed ID for alarm notifications
        '🚨 Urgent Alert: ${deviceName ?? 'Device'}',
        reason,
        notificationDetails,
      );

      debugPrint('✅ Persistent notification shown');
    } catch (e) {
      debugPrint('❌ Failed to show persistent notification: $e');
    }
  }

  /// Cancel persistent notification
  Future<void> _cancelPersistentNotification() async {
    try {
      await _notificationsPlugin.cancel(999);
      debugPrint('✅ Persistent notification cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel notification: $e');
    }
  }

  /// Dispose of the service
  void dispose() {
    _beepTimer?.cancel();
    _beepTimer = null;
    _snoozeTimer?.cancel();
    _snoozeTimer = null;
    _isAlarmActive = false;
    _audioPlayer.dispose();
  }
}
