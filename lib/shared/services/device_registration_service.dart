import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_manager.dart';

/// Model for device registration data
class DeviceRegistrationData {
  final String macAddress;
  final String deviceName;
  final int timestamp;
  
  DeviceRegistrationData({
    required this.macAddress,
    required this.deviceName,
    required this.timestamp,
  });
  
  factory DeviceRegistrationData.fromJson(Map<String, dynamic> json) {
    return DeviceRegistrationData(
      macAddress: json['macAddress']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? '',
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}

/// Service for listening to device registration messages on MQTT
/// Monitors system/devices/register topic for new ESP32 devices
class DeviceRegistrationService extends ChangeNotifier {
  static const String registrationTopic = 'system/devices/register';
  
  bool _isListening = false;
  String? _error;
  DeviceRegistrationData? _latestRegistration;
  
  final StreamController<DeviceRegistrationData> _registrationController = 
      StreamController<DeviceRegistrationData>.broadcast();
  
  // Getters
  bool get isListening => _isListening;
  String? get error => _error;
  Stream<DeviceRegistrationData> get onDeviceRegistered => _registrationController.stream;
  DeviceRegistrationData? get latestRegistration => _latestRegistration;
  
  /// Start listening for device registrations
  Future<bool> startListening() async {
    try {
      debugPrint('📡 DeviceRegistrationService: Starting to listen for registrations...');
      
      // Ensure MQTT is connected
      if (!MqttManager.instance.isConnected) {
        debugPrint('🔌 DeviceRegistrationService: MQTT not connected, initializing...');
        await MqttManager.instance.initialize();
        
        // Wait a bit for connection
        await Future.delayed(const Duration(seconds: 2));
        
        if (!MqttManager.instance.isConnected) {
          _error = 'Failed to connect to MQTT broker';
          debugPrint('❌ DeviceRegistrationService: $_error');
          notifyListeners();
          return false;
        }
      }
      
      // Register this service as a "device" to receive messages
      await MqttManager.instance.registerDevice(
        'registration_listener',
        _handleRegistrationMessage,
      );
      
      // Subscribe to registration topic
      MqttManager.instance.client.subscribe(
        registrationTopic,
        MqttQos.atLeastOnce,
      );
      
      _isListening = true;
      _error = null;
      
      debugPrint('✅ DeviceRegistrationService: Now listening on $registrationTopic');
      notifyListeners();
      return true;
      
    } catch (e) {
      _error = 'Failed to start listening: $e';
      debugPrint('❌ DeviceRegistrationService: $_error');
      notifyListeners();
      return false;
    }
  }
  
  /// Handle incoming registration messages
  void _handleRegistrationMessage(String topic, String message) {
    if (topic != registrationTopic) return;
    
    try {
      debugPrint('📨 DeviceRegistrationService: Received registration message');
      debugPrint('   Topic: $topic');
      debugPrint('   Message: $message');
      
      // Parse JSON message
      final Map<String, dynamic> data = jsonDecode(message);
      final registration = DeviceRegistrationData.fromJson(data);
      
      // Validate required fields
      if (registration.macAddress.isEmpty || registration.deviceName.isEmpty) {
        debugPrint('⚠️ DeviceRegistrationService: Invalid registration - missing required fields');
        return;
      }
      
      _latestRegistration = registration;
      
      debugPrint('✅ DeviceRegistrationService: Parsed registration:');
      debugPrint('   MAC Address: ${registration.macAddress}');
      debugPrint('   Device Name: ${registration.deviceName}');
      debugPrint('   Timestamp: ${registration.timestamp}');
      
      // Notify listeners via stream
      _registrationController.add(registration);
      notifyListeners();
      
    } catch (e) {
      _error = 'Failed to parse registration message: $e';
      debugPrint('❌ DeviceRegistrationService: $_error');
      debugPrint('   Raw message: $message');
      notifyListeners();
    }
  }
  
  /// Stop listening for registrations
  Future<void> stopListening() async {
    try {
      debugPrint('🛑 DeviceRegistrationService: Stopping listener...');
      
      // Unsubscribe from topic
      if (MqttManager.instance.isConnected) {
        MqttManager.instance.client.unsubscribe(registrationTopic);
      }
      
      // Unregister from MQTT manager
      await MqttManager.instance.unregisterDevice('registration_listener');
      
      _isListening = false;
      
      debugPrint('✅ DeviceRegistrationService: Stopped listening');
      notifyListeners();
      
    } catch (e) {
      debugPrint('⚠️ DeviceRegistrationService: Error stopping listener: $e');
    }
  }
  
  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Reset latest registration
  void clearLatestRegistration() {
    _latestRegistration = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopListening();
    _registrationController.close();
    super.dispose();
  }
}
