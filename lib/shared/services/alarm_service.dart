import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  AlarmService._internal();

  static const MethodChannel _channel = MethodChannel('alarm_channel');
  final FlutterTts _tts = FlutterTts();
  
  Timer? _beepTimer;
  bool _isAlarmActive = false;
  String? _currentAlarmReason;

  bool get isAlarmActive => _isAlarmActive;
  String? get currentAlarmReason => _currentAlarmReason;

  /// Start the alarm with continuous beeping
  Future<void> startAlarm(String reason) async {
    if (_isAlarmActive) return; // Already active
    
    _isAlarmActive = true;
    _currentAlarmReason = reason;
    
    debugPrint('🚨 ALARM STARTED: $reason');
    
    // Announce the alarm reason once
    await _tts.speak('Urgent Alert: $reason');
    
    // Start continuous beeping every 2 seconds
    _beepTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _playBeep();
    });
    
    // Play first beep immediately
    await _playBeep();
  }

  /// Stop the alarm
  Future<void> stopAlarm() async {
    if (!_isAlarmActive) return;
    
    debugPrint('🔇 ALARM STOPPED');
    
    _beepTimer?.cancel();
    _beepTimer = null;
    _isAlarmActive = false;
    _currentAlarmReason = null;
    
    // Announce alarm stopped
    await _tts.speak('Alert cleared');
  }

  /// Play a single beep sound
  Future<void> _playBeep() async {
    try {
      // Try to use platform channel for system beep
      await _channel.invokeMethod('playBeep');
    } catch (e) {
      // Fallback: Use haptic feedback and TTS beep
      debugPrint('⚠️ Platform beep not available, using fallback');
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.heavyImpact();
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

  /// Dispose of the service
  void dispose() {
    _beepTimer?.cancel();
    _beepTimer = null;
    _isAlarmActive = false;
  }
}
