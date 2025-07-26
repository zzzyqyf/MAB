import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'mqtt_manager.dart';

/// Device-specific MQTT service that handles sensor data for a single device
class MqttService extends ChangeNotifier {
  final String deviceId;
  final Function(
    double?, double?, int?, int?, double?, double?,  // sensor values
    int?, int?, int?, int?, int?, int?               // timestamps
  ) onDataReceived;
  final Function(String id, String newStatus) onDeviceConnectionStatusChange;

  // Sensor data
  double? temperature;
  double? humidity;
  int? lightState;
  int? blueLightState;
  double? co2Level;
  double? moisture;
  String? deviceStatus;

  // Sensor timestamps (ESP32 timestamps when available)
  int? temperatureTimestamp;
  int? humidityTimestamp;
  int? lightTimestamp;
  int? blueLightTimestamp;
  int? co2Timestamp;
  int? moistureTimestamp;
  int? statusTimestamp;

  // Connection tracking
  final Map<String, DateTime> _lastReceivedTimestamps = {};
  Timer? _dataCheckTimer;
  bool _isDisposed = false;

  MqttService({
    required this.deviceId,
    required this.onDataReceived,
    required this.onDeviceConnectionStatusChange,
  });

  /// Initialize the MQTT service and register with centralized manager
  Future<void> setupMqttClient() async {
    if (_isDisposed) return;

    try {
      // Register this device with the centralized MQTT manager
      await MqttManager.instance.registerDevice(deviceId, handleMessage);
      
      debugPrint('MqttService: Device $deviceId registered with MQTT manager');
      
      // Start periodic data checking
      _startDataChecking();
      
      // Send initial device registration message
      await _announceDevice();
      
    } catch (e) {
      debugPrint('MqttService: Failed to setup MQTT for device $deviceId: $e');
      onDeviceConnectionStatusChange(deviceId, 'error');
    }
  }

  /// Handle incoming MQTT messages for this device
  /// Helper function to parse sensor values from various formats
  double? _parseValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parse JSON payload with timestamp, fallback to simple value
  Map<String, dynamic> _parseJsonPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return {
          'value': _parseValue(decoded['value']),
          'timestamp': decoded['timestamp']?.toInt(),
        };
      } else {
        // Fallback for simple numeric value
        return {
          'value': _parseValue(payload),
          'timestamp': null,
        };
      }
    } catch (e) {
      // Fallback for non-JSON payload
      return {
        'value': _parseValue(payload),
        'timestamp': null,
      };
    }
  }

  void handleMessage(String topic, String message) {
    if (_isDisposed) return;

    debugPrint('📨 MqttService [$deviceId]: Received $topic → $message');

    try {
      bool dataUpdated = false;
      
      // Parse device-specific sensor topics with JSON timestamp support
      if (topic == 'devices/$deviceId/sensors/temperature') {
        final result = _parseJsonPayload(message);
        final newTemp = result['value'];
        if (newTemp != null && newTemp != temperature) {
          temperature = newTemp;
          temperatureTimestamp = result['timestamp'];
          dataUpdated = true;
          debugPrint('🌡️ Temperature updated: $temperature°C');
        }
      } else if (topic == 'devices/$deviceId/sensors/humidity') {
        final result = _parseJsonPayload(message);
        final newHumidity = result['value'];
        if (newHumidity != null && newHumidity != humidity) {
          humidity = newHumidity;
          humidityTimestamp = result['timestamp'];
          dataUpdated = true;
          debugPrint('💧 Humidity updated: $humidity%');
        }
      } else if (topic == 'devices/$deviceId/sensors/lights') {
        final result = _parseJsonPayload(message);
        final newLightState = result['value']?.toInt();
        if (newLightState != null && newLightState != lightState) {
          lightState = newLightState;
          lightTimestamp = result['timestamp'];
          dataUpdated = true;
          debugPrint('💡 Light state updated: $lightState');
        }
      } else if (topic == 'devices/$deviceId/sensors/bluelight') {
        final result = _parseJsonPayload(message);
        final newBlueLightState = result['value']?.toInt();
        if (newBlueLightState != null && newBlueLightState != blueLightState) {
          blueLightState = newBlueLightState;
          blueLightTimestamp = result['timestamp'];
          dataUpdated = true;
          debugPrint('🔵 Blue light updated: $blueLightState');
        }
      } else if (topic == 'devices/$deviceId/sensors/co2') {
        final result = _parseJsonPayload(message);
        final newCo2Level = result['value'];
        if (newCo2Level != null && newCo2Level != co2Level) {
          co2Level = newCo2Level;
          co2Timestamp = result['timestamp'];
          dataUpdated = true;
          debugPrint('🌫️ CO2 level updated: $co2Level ppm');
        }
      } else if (topic == 'devices/$deviceId/sensors/moisture') {
        final result = _parseJsonPayload(message);
        final newMoisture = result['value'];
        if (newMoisture != null && newMoisture != moisture) {
          moisture = newMoisture;
          moistureTimestamp = result['timestamp'];
          dataUpdated = true;
          debugPrint('🌱 Moisture updated: $moisture%');
        }
      } else if (topic == 'devices/$deviceId/status') {
        if (message != deviceStatus) {
          deviceStatus = message;
          debugPrint('📶 Device status updated: $deviceStatus');
          onDeviceConnectionStatusChange(deviceId, message);
        }
      } else if (topic == 'devices/$deviceId/info') {
        _handleDeviceInfo(message);
      } else if (topic == 'devices/$deviceId/config/response') {
        _handleConfigResponse(message);
      }

      if (dataUpdated) {
        _lastReceivedTimestamps[deviceId] = DateTime.now();
        
        debugPrint('📊 Triggering callback with: temp=$temperature, humidity=$humidity, light=$lightState, bluelight=$blueLightState, co2=$co2Level, moisture=$moisture');
        onDataReceived(
          temperature, humidity, lightState, blueLightState, co2Level, moisture,
          temperatureTimestamp, humidityTimestamp, lightTimestamp, blueLightTimestamp, co2Timestamp, moistureTimestamp
        );
        
        if (!_isDisposed) {
          notifyListeners();
        }
      }
      
    } catch (e) {
      debugPrint('MqttService: Error handling message for device $deviceId: $e');
    }
  }

  void _handleDeviceInfo(String message) {
    try {
      final info = jsonDecode(message) as Map<String, dynamic>;
      debugPrint('MqttService: Device $deviceId info updated: $info');
      // Handle device info updates (firmware version, capabilities, etc.)
    } catch (e) {
      debugPrint('MqttService: Error parsing device info: $e');
    }
  }

  void _handleConfigResponse(String message) {
    try {
      final config = jsonDecode(message) as Map<String, dynamic>;
      debugPrint('MqttService: Device $deviceId config response: $config');
      // Handle configuration responses
    } catch (e) {
      debugPrint('MqttService: Error parsing config response: $e');
    }
  }

  void _startDataChecking() {
    _dataCheckTimer?.cancel();
    _dataCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _checkDataReception();
    });
  }

  void _checkDataReception() {
    final isDataReceivedFlag = isDataReceived(deviceId);
    final status = isDataReceivedFlag ? 'online' : 'offline';
    onDeviceConnectionStatusChange(deviceId, status);
    
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Check if device has sent data recently
  bool isDataReceived(String deviceId) {
    final lastDataTime = _lastReceivedTimestamps[deviceId];
    if (lastDataTime == null) return false;
    return DateTime.now().difference(lastDataTime).inSeconds <= 60; // 1 minute timeout
  }

  /// Announce this device to the system
  Future<void> _announceDevice() async {
    final deviceInfo = {
      'deviceId': deviceId,
      'deviceName': 'ESP32 Device $deviceId',
      'location': 'Unknown',
      'capabilities': ['temperature', 'humidity', 'lights', 'moisture'],
      'firmware': 'v1.0.0',
      'lastSeen': DateTime.now().toIso8601String(),
      'metadata': {
        'type': 'ESP32',
        'clientType': 'flutter_app'
      }
    };

    await MqttManager.instance.publishMessage(
      'system/devices/register',
      jsonEncode(deviceInfo),
    );

    // Also publish to device-specific info topic
    await MqttManager.instance.publishMessage(
      'devices/$deviceId/info',
      jsonEncode(deviceInfo),
    );
  }

  /// Send a command to the device
  Future<void> sendCommand(String command, {Map<String, dynamic>? parameters}) async {
    await MqttManager.instance.sendDeviceCommand(deviceId, command, parameters: parameters);
  }

  /// Send configuration to the device
  Future<void> sendConfiguration(Map<String, dynamic> config) async {
    await MqttManager.instance.sendDeviceConfig(deviceId, config);
  }

  /// Request current configuration from device
  Future<void> requestConfiguration() async {
    await MqttManager.instance.requestDeviceConfig(deviceId);
  }

  /// Control device lights
  Future<void> controlLights(bool turnOn) async {
    await sendCommand('lights', parameters: {'state': turnOn ? 'on' : 'off'});
  }

  /// Set moisture sensor calibration
  Future<void> calibrateMoistureSensor(double dryValue, double wetValue) async {
    await sendCommand('calibrate_moisture', parameters: {
      'dry_value': dryValue,
      'wet_value': wetValue,
    });
  }

  /// Set sensor reading interval
  Future<void> setSensorInterval(int intervalSeconds) async {
    await sendConfiguration({
      'sensor_interval': intervalSeconds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get device connection status
  String getConnectionStatus() {
    if (!MqttManager.instance.isConnected) return 'broker_offline';
    if (!isDataReceived(deviceId)) return 'device_offline';
    return 'online';
  }

  /// Get last data received timestamp
  DateTime? getLastDataTimestamp() {
    return _lastReceivedTimestamps[deviceId];
  }

  /// Get current sensor readings as a map
  Map<String, dynamic> getCurrentReadings() {
    return {
      'deviceId': deviceId,
      'temperature': temperature,
      'humidity': humidity,
      'lightState': lightState,
      'moisture': moisture,
      'status': getConnectionStatus(),
      'lastUpdated': getLastDataTimestamp()?.toIso8601String(),
    };
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dataCheckTimer?.cancel();
    
    // Unregister from MQTT manager
    MqttManager.instance.unregisterDevice(deviceId);
    
    debugPrint('MqttService: Device $deviceId disposed');
    super.dispose();
  }
}
