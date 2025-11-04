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
    if (topic == 'devices/$deviceId/actuators/status') {
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
    final payload = jsonEncode({
      'mode': 'normal',
    });
    
    await MqttManager.instance.publishMessage(
      'devices/$deviceId/mode/set',
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
    final durationSeconds = durationHours * 3600;
    
    final payload = jsonEncode({
      'mode': 'pinning',
      'duration': durationSeconds,
    });
    
    await MqttManager.instance.publishMessage(
      'devices/$deviceId/mode/set',
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
  
  @override
  void dispose() {
    // Note: This should only be called via removeInstance() when device is removed
    // NOT when widgets are disposed (since this is a singleton)
    super.dispose();
  }
}
