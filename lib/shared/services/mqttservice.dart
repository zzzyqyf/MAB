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
  String? mode; // Current mode: 'n' (normal) or 'p' (pinning)
  int? countdownSeconds; // Remaining time in pinning mode

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
  String? _lastReportedStatus; // Track last reported status to avoid spam
  
  // Status debouncing - prevent rapid flipping
  int _consecutiveOfflineChecks = 0;
  int _consecutiveOnlineChecks = 0;
  static const int _requiredConsecutiveChecks = 3; // Must be stable for 3 checks (30s)

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
      
      // Handle new unified sensor topic: topic/{deviceId} with payload [humidity,light,temp,water,mode]
      if (topic == 'topic/$deviceId') {
        final parsed = _parseUnifiedSensorData(message);
        if (parsed != null) {
          // Update all sensor values from unified payload
          if (parsed['humidity'] != null && parsed['humidity'] != humidity) {
            humidity = parsed['humidity'];
            humidityTimestamp = DateTime.now().millisecondsSinceEpoch;
            dataUpdated = true;
            debugPrint('💧 Humidity updated: $humidity%');
          }
          if (parsed['light'] != null && parsed['light']?.toInt() != lightState) {
            lightState = parsed['light']?.toInt();
            lightTimestamp = DateTime.now().millisecondsSinceEpoch;
            dataUpdated = true;
            debugPrint('💡 Light updated: $lightState');
          }
          if (parsed['temperature'] != null && parsed['temperature'] != temperature) {
            temperature = parsed['temperature'];
            temperatureTimestamp = DateTime.now().millisecondsSinceEpoch;
            dataUpdated = true;
            debugPrint('🌡️ Temperature updated: $temperature°C');
          }
          if (parsed['water'] != null && parsed['water'] != moisture) {
            moisture = parsed['water'];
            moistureTimestamp = DateTime.now().millisecondsSinceEpoch;
            dataUpdated = true;
            debugPrint('💧 Water Level updated: $moisture%');
          }
          if (parsed['mode'] != null && parsed['mode'] != mode) {
            mode = parsed['mode'] as String?;
            dataUpdated = true;
            debugPrint('🌿 Mode updated: ${mode == "p" ? "PINNING" : "NORMAL"}');
          }
        }
      }
      // Handle alarm topic: topic/{deviceId}/alarm
      else if (topic == 'topic/$deviceId/alarm') {
        debugPrint('🚨 ALARM received for device $deviceId: $message');
        // Alarm will be handled by Cloud Function -> FCM
        // This is just for logging/debugging
      }
      // Handle countdown topic: topic/{deviceId}/countdown
      else if (topic == 'topic/$deviceId/countdown') {
        final newCountdown = int.tryParse(message);
        if (newCountdown != null && newCountdown != countdownSeconds) {
          countdownSeconds = newCountdown;
          dataUpdated = true;
          debugPrint('⏱️ Countdown updated: $countdownSeconds seconds (${(countdownSeconds! / 3600).toStringAsFixed(1)}h)');
        }
      }
      // Handle mode status: topic/{deviceId}/mode/status
      else if (topic == 'topic/$deviceId/mode/status') {
        if (message != mode) {
          mode = message;
          dataUpdated = true;
          debugPrint('🌿 Mode status updated: ${mode == "p" ? "PINNING" : "NORMAL"}');
        }
      }
      // Handle device status: topic/{deviceId}/status
      else if (topic == 'topic/$deviceId/status') {
        if (message != deviceStatus) {
          deviceStatus = message;
          debugPrint('� Device status updated: $deviceStatus');
          onDeviceConnectionStatusChange(deviceId, message);
        }
      }
      // Legacy topics for backward compatibility (will be removed)
      else if (topic == 'devices/$deviceId/sensors/temperature') {
        final result = _parseJsonPayload(message);
        final newTemp = result['value'];
        if (newTemp != null && newTemp != temperature) {
          temperature = newTemp;
          temperatureTimestamp = result['timestamp'];
          dataUpdated = true;
          debugPrint('🌡️ Temperature updated (legacy): $temperature°C');
        }
      } else if (topic == 'devices/$deviceId/sensors/humidity') {
        final result = _parseJsonPayload(message);
        final newHumidity = result['value'];
        if (newHumidity != null && newHumidity != humidity) {
          humidity = newHumidity;
          humidityTimestamp = result['timestamp'];
          dataUpdated = true;
          debugPrint('💧 Humidity updated (legacy): $humidity%');
        }
      } else if (topic == 'devices/$deviceId/sensors/moisture' || topic == 'devices/$deviceId/sensors/water_level') {
        final result = _parseJsonPayload(message);
        final newMoisture = result['value'];
        if (newMoisture != null && newMoisture != moisture) {
          moisture = newMoisture;
          moistureTimestamp = result['timestamp'];
          dataUpdated = true;
          debugPrint('💧 Water Level/Moisture updated (legacy): $moisture%');
        }
      } else if (topic == 'devices/$deviceId/status') {
        if (message != deviceStatus) {
          deviceStatus = message;
          debugPrint('📶 Device status updated (legacy): $deviceStatus');
          onDeviceConnectionStatusChange(deviceId, message);
        }
      }

      if (dataUpdated) {
        _lastReceivedTimestamps[deviceId] = DateTime.now();
        
        debugPrint('📊 Triggering callback with: temp=$temperature, humidity=$humidity, light=$lightState, moisture=$moisture, mode=$mode');
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

  /// Parse unified sensor data format: [humidity,temperature,water] or [humidity,light,temp,water] or [humidity,light,temp,water,mode]
  /// Example: "[72.2,28.8,1]" or "[72,47,28,60]" or "[72.2,47.0,28.8,60.5,n]"
  /// Water level: 0 = no water (urgent), 1 = good status
  Map<String, dynamic>? _parseUnifiedSensorData(String payload) {
    try {
      // Remove brackets and split by comma
      String cleaned = payload.trim();
      if (cleaned.startsWith('[')) cleaned = cleaned.substring(1);
      if (cleaned.endsWith(']')) cleaned = cleaned.substring(0, cleaned.length - 1);
      
      List<String> parts = cleaned.split(',');
      if (parts.length < 3) {
        debugPrint('⚠️ Invalid unified sensor data format: expected at least 3 values, got ${parts.length}');
        return null;
      }
      
      // Parse based on number of values
      if (parts.length == 3) {
        // New format: [humidity, temperature, water]
        final waterValue = double.tryParse(parts[2].trim());
        return {
          'humidity': double.tryParse(parts[0].trim()),
          'light': null, // No light sensor data
          'temperature': double.tryParse(parts[1].trim()),
          'water': waterValue,
          'waterStatus': waterValue == 1 ? 'High' : (waterValue == 0 ? 'Low' : 'Unknown'),
          'mode': 'n', // Default to normal mode
        };
      } else if (parts.length == 4) {
        // Format: [humidity, light, temperature, water]
        final waterValue = double.tryParse(parts[3].trim());
        return {
          'humidity': double.tryParse(parts[0].trim()),
          'light': double.tryParse(parts[1].trim()),
          'temperature': double.tryParse(parts[2].trim()),
          'water': waterValue,
          'waterStatus': waterValue == 1 ? 'High' : (waterValue == 0 ? 'Low' : 'Unknown'),
          'mode': 'n', // Default to normal mode
        };
      } else {
        // Format: [humidity, light, temperature, water, mode]
        final waterValue = double.tryParse(parts[3].trim());
        return {
          'humidity': double.tryParse(parts[0].trim()),
          'light': double.tryParse(parts[1].trim()),
          'temperature': double.tryParse(parts[2].trim()),
          'water': waterValue,
          'waterStatus': waterValue == 1 ? 'High' : (waterValue == 0 ? 'Low' : 'Unknown'),
          'mode': parts[4].trim(), // 'n' or 'p' as String
        };
      }
    } catch (e) {
      debugPrint('❌ Error parsing unified sensor data: $e');
      return null;
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
    final currentStatus = isDataReceivedFlag ? 'online' : 'offline';
    
    // Debouncing logic: require multiple consecutive checks before changing status
    if (currentStatus == 'online') {
      _consecutiveOnlineChecks++;
      _consecutiveOfflineChecks = 0;
    } else {
      _consecutiveOfflineChecks++;
      _consecutiveOnlineChecks = 0;
    }
    
    // Determine if we should update status
    bool shouldUpdate = false;
    String? newStatus;
    
    if (_lastReportedStatus == null) {
      // First check - set status immediately
      shouldUpdate = true;
      newStatus = currentStatus;
    } else if (_lastReportedStatus == 'online' && _consecutiveOfflineChecks >= _requiredConsecutiveChecks) {
      // Was online, now consistently offline
      shouldUpdate = true;
      newStatus = 'offline';
      debugPrint('⚠️ MqttService: Device $deviceId going offline after ${_consecutiveOfflineChecks} consecutive checks (${_getTimeSinceLastData()}s since last data)');
    } else if (_lastReportedStatus == 'offline' && _consecutiveOnlineChecks >= 1) {
      // Was offline, got data - immediately mark online (faster recovery)
      shouldUpdate = true;
      newStatus = 'online';
      debugPrint('✅ MqttService: Device $deviceId back online (received data)');
    }
    
    // Update status if needed
    if (shouldUpdate && newStatus != null) {
      _lastReportedStatus = newStatus;
      onDeviceConnectionStatusChange(deviceId, newStatus);
      
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  /// Check if device has sent data recently
  bool isDataReceived(String deviceId) {
    final lastDataTime = _lastReceivedTimestamps[deviceId];
    if (lastDataTime == null) return false;
    return DateTime.now().difference(lastDataTime).inSeconds <= 90; // 90 second timeout (increased for stability)
  }
  
  /// Helper to get time since last data for debugging
  int _getTimeSinceLastData() {
    final lastDataTime = _lastReceivedTimestamps[deviceId];
    if (lastDataTime == null) return -1;
    return DateTime.now().difference(lastDataTime).inSeconds;
  }

  /// Announce this device to the system
  Future<void> _announceDevice() async {
    final deviceInfo = {
      'deviceId': deviceId,
      'deviceName': 'ESP32 Device $deviceId',
      'location': 'Unknown',
      'capabilities': ['temperature', 'humidity', 'lights', 'moisture', 'water_level'],
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
