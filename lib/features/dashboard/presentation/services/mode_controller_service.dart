import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../shared/services/mqtt_manager.dart';
import '../models/mushroom_phase.dart';

/// Service to manage cultivation mode and timer for devices
class ModeControllerService extends ChangeNotifier {
  final String deviceId;
  
  // Static map to store singleton instances per device
  static final Map<String, ModeControllerService> _instances = {};
  
  /// Get or create singleton instance for a device
  factory ModeControllerService({required String deviceId}) {
    if (!_instances.containsKey(deviceId)) {
      _instances[deviceId] = ModeControllerService._internal(deviceId: deviceId);
    }
    return _instances[deviceId]!;
  }
  
  // Private constructor
  ModeControllerService._internal({required this.deviceId}) {
    _setupMqttListener();
    debugPrint('🎯 ModeControllerService: Created singleton instance for $deviceId');
  }
  
  CultivationMode _currentMode = CultivationMode.normal;
  DateTime? _pinningEndTime;
  bool _isPinningActive = false;
  
  // Actuator states received from ESP32
  bool humidifier1On = false;
  bool humidifier2On = false;
  bool fan1On = false;
  bool fan2On = false;
  
  CultivationMode get currentMode => _currentMode;
  DateTime? get pinningEndTime => _pinningEndTime;
  bool get isPinningActive => _isPinningActive;
  
  /// Get remaining time for pinning mode in seconds
  int? get remainingSeconds {
    if (!_isPinningActive || _pinningEndTime == null) return null;
    final remaining = _pinningEndTime!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
  
  /// Get formatted remaining time (HH:MM:SS)
  String? get formattedRemainingTime {
    final seconds = remainingSeconds;
    if (seconds == null) return null;
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  /// Setup MQTT listener for actuator status updates
  void _setupMqttListener() {
    // Register to receive actuator status updates
    MqttManager.instance.registerDevice(deviceId, _handleActuatorStatus);
  }
  
  /// Handle incoming MQTT messages
  void _handleActuatorStatus(String topic, String message) {
    // Handle new countdown topic: topic/{deviceId}/countdown
    if (topic == 'topic/$deviceId/countdown') {
      try {
        final remainingSecs = int.tryParse(message);
        if (remainingSecs != null) {
          _pinningEndTime = DateTime.now().add(Duration(seconds: remainingSecs));
          debugPrint('⏱️ Countdown received from ESP32: $remainingSecs seconds (${formattedRemainingTime})');
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error parsing countdown: $e');
      }
    }
    // Handle new mode status topic: topic/{deviceId}/mode/status
    else if (topic == 'topic/$deviceId/mode/status') {
      if (message == 'p') {
        _currentMode = CultivationMode.pinning;
        _isPinningActive = true;
        debugPrint('🌿 Mode updated to PINNING from ESP32');
      } else if (message == 'n') {
        _currentMode = CultivationMode.normal;
        _isPinningActive = false;
        _pinningEndTime = null;
        debugPrint('🌿 Mode updated to NORMAL from ESP32');
      }
      notifyListeners();
    }
    // Legacy topic support (will be removed)
    else if (topic == 'devices/$deviceId/actuators/status') {
      try {
        final data = jsonDecode(message) as Map<String, dynamic>;
        
        humidifier1On = data['humidifier1'] == 'on';
        humidifier2On = data['humidifier2'] == 'on';
        fan1On = data['fan1'] == 'on';
        fan2On = data['fan2'] == 'on';
        
        // Update mode from ESP32 feedback
        if (data['mode'] == 'pinning') {
          _currentMode = CultivationMode.pinning;
          _isPinningActive = true;
          
          // Update remaining time if provided
          if (data.containsKey('pinning_remaining')) {
            final remainingSecs = data['pinning_remaining'] as int;
            _pinningEndTime = DateTime.now().add(Duration(seconds: remainingSecs));
          }
        } else {
          _currentMode = CultivationMode.normal;
          _isPinningActive = false;
          _pinningEndTime = null;
        }
        
        notifyListeners();
      } catch (e) {
        debugPrint('Error parsing actuator status: $e');
      }
    } else if (topic == 'devices/$deviceId/mode/status') {
      // Mode confirmation from ESP32
      if (message == 'normal') {
        _currentMode = CultivationMode.normal;
        _isPinningActive = false;
        _pinningEndTime = null;
      } else if (message == 'pinning') {
        _currentMode = CultivationMode.pinning;
        _isPinningActive = true;
      }
      notifyListeners();
    }
  }
  
  /// Set cultivation mode to Normal
  Future<void> setNormalMode() async {
    debugPrint('🚀 ModeController: setNormalMode() called for $deviceId');
    
    // New topic format: topic/{deviceId}/mode/set with payload: "n,0"
    final payload = 'n,0';
    
    debugPrint('📤 ModeController: Publishing to topic/$deviceId/mode/set with payload: $payload');
    
    await MqttManager.instance.publishMessage(
      'topic/$deviceId/mode/set',
      payload,
    );
    
    _currentMode = CultivationMode.normal;
    _isPinningActive = false;
    _pinningEndTime = null;
    notifyListeners();
    
    debugPrint('✅ ModeController: Device $deviceId set to Normal mode');
    debugPrint('📢 ModeController: Notifying all listeners about mode change');
  }
  
  /// Set cultivation mode to Pinning with timer
  Future<void> setPinningMode(int durationHours) async {
    debugPrint('🚀 ModeController: setPinningMode() called for $deviceId with duration: $durationHours hours');
    
    final durationSeconds = durationHours * 3600;
    
    // New topic format: topic/{deviceId}/mode/set with payload: "p,3600"
    final payload = 'p,$durationSeconds';
    
    debugPrint('📤 ModeController: Publishing to topic/$deviceId/mode/set with payload: $payload');
    
    await MqttManager.instance.publishMessage(
      'topic/$deviceId/mode/set',
      payload,
    );
    
    _currentMode = CultivationMode.pinning;
    _isPinningActive = true;
    _pinningEndTime = DateTime.now().add(Duration(seconds: durationSeconds));
    notifyListeners();
    
    debugPrint('✅ ModeController: Device $deviceId set to Pinning mode for $durationHours hours');
    debugPrint('📢 ModeController: Notifying all listeners about mode change');
  }
  
  /// Cancel pinning mode and revert to Normal
  Future<void> cancelPinningMode() async {
    await setNormalMode();
  }
  
  /// Cleanup singleton instance (call only when device is removed)
  static void removeInstance(String deviceId) {
    final instance = _instances[deviceId];
    if (instance != null) {
      MqttManager.instance.unregisterDevice(deviceId);
      instance.dispose();
      _instances.remove(deviceId);
      debugPrint('🗑️ ModeControllerService: Removed singleton instance for $deviceId');
    }
  }
  
  /// Clear all singleton instances (call when user logs out)
  static void clearAllInstances() {
    debugPrint('🧹 ModeControllerService: Clearing all singleton instances');
    for (var deviceId in _instances.keys.toList()) {
      removeInstance(deviceId);
    }
    _instances.clear();
    debugPrint('✅ ModeControllerService: All instances cleared');
  }
  
  @override
  void dispose() {
    // Note: This should only be called via removeInstance() when device is removed
    // NOT when widgets are disposed (since this is a singleton)
    super.dispose();
  }
}
