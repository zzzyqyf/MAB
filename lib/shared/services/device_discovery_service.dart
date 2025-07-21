import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Model for device discovery information
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String location;
  final List<String> capabilities;
  final String firmware;
  final DateTime lastSeen;
  final Map<String, dynamic>? metadata;

  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.location,
    required this.capabilities,
    required this.firmware,
    required this.lastSeen,
    this.metadata,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      location: json['location'] as String? ?? 'Unknown',
      capabilities: List<String>.from(json['capabilities'] as List? ?? []),
      firmware: json['firmware'] as String? ?? 'Unknown',
      lastSeen: DateTime.parse(json['lastSeen'] as String? ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'location': location,
      'capabilities': capabilities,
      'firmware': firmware,
      'lastSeen': lastSeen.toIso8601String(),
      'metadata': metadata,
    };
  }

  DeviceInfo copyWith({
    String? deviceId,
    String? deviceName,
    String? location,
    List<String>? capabilities,
    String? firmware,
    DateTime? lastSeen,
    Map<String, dynamic>? metadata,
  }) {
    return DeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      location: location ?? this.location,
      capabilities: capabilities ?? this.capabilities,
      firmware: firmware ?? this.firmware,
      lastSeen: lastSeen ?? this.lastSeen,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Service for discovering and managing ESP32 devices via MQTT
class DeviceDiscoveryService extends ChangeNotifier {
  static const String mqttBroker = 'broker.mqtt.cool';
  static const int mqttPort = 1883;
  
  late MqttServerClient _client;
  final Map<String, DeviceInfo> _discoveredDevices = {};
  final Map<String, DateTime> _deviceHeartbeats = {};
  
  Timer? _heartbeatTimer;
  Timer? _discoveryTimer;
  bool _isConnected = false;
  
  // Stream controllers for device events
  final StreamController<DeviceInfo> _deviceRegisteredController = StreamController<DeviceInfo>.broadcast();
  final StreamController<String> _deviceUnregisteredController = StreamController<String>.broadcast();
  final StreamController<DeviceInfo> _deviceUpdatedController = StreamController<DeviceInfo>.broadcast();
  
  // Public streams
  Stream<DeviceInfo> get deviceRegistered => _deviceRegisteredController.stream;
  Stream<String> get deviceUnregistered => _deviceUnregisteredController.stream;
  Stream<DeviceInfo> get deviceUpdated => _deviceUpdatedController.stream;
  
  // Getters
  Map<String, DeviceInfo> get discoveredDevices => Map.unmodifiable(_discoveredDevices);
  bool get isConnected => _isConnected;
  
  DeviceDiscoveryService() {
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _setupMqttClient();
    _startHeartbeatMonitoring();
  }

  Future<void> _setupMqttClient() async {
    _client = MqttServerClient(mqttBroker, 'DiscoveryService_${DateTime.now().millisecondsSinceEpoch}');
    _client.port = mqttPort;
    _client.logging(on: true);
    _client.keepAlivePeriod = 30;
    _client.autoReconnect = true;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onAutoReconnect = _onAutoReconnect;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('DeviceDiscovery_${DateTime.now().millisecondsSinceEpoch}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client.connectionMessage = connMessage;

    try {
      debugPrint('DeviceDiscoveryService: Connecting to MQTT broker...');
      await _client.connect();
    } catch (e) {
      debugPrint('DeviceDiscoveryService: Connection failed: $e');
      _client.disconnect();
    }
  }

  void _onConnected() {
    debugPrint('DeviceDiscoveryService: Connected to MQTT broker');
    _isConnected = true;
    _subscribeToSystemTopics();
    notifyListeners();
    
    // Request all devices to announce themselves
    _requestDeviceDiscovery();
  }

  void _onDisconnected() {
    debugPrint('DeviceDiscoveryService: Disconnected from MQTT broker');
    _isConnected = false;
    notifyListeners();
  }

  void _onAutoReconnect() {
    debugPrint('DeviceDiscoveryService: Auto-reconnecting to MQTT broker');
  }

  void _subscribeToSystemTopics() {
    // Subscribe to system-level topics for device management
    _client.subscribe('system/devices/register', MqttQos.atLeastOnce);
    _client.subscribe('system/devices/heartbeat', MqttQos.atLeastOnce);
    _client.subscribe('system/devices/unregister', MqttQos.atLeastOnce);
    
    // Subscribe to device-specific info topics using wildcards
    _client.subscribe('devices/+/info', MqttQos.atLeastOnce);
    _client.subscribe('devices/+/status', MqttQos.atLeastOnce);

    _client.updates!.listen(_handleMqttMessage);
  }

  void _handleMqttMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = MqttPublishPayload.bytesToStringAsString(
        (message.payload as MqttPublishMessage).payload.message
      );

      try {
        if (topic == 'system/devices/register') {
          _handleDeviceRegistration(payload);
        } else if (topic == 'system/devices/heartbeat') {
          _handleDeviceHeartbeat(payload);
        } else if (topic == 'system/devices/unregister') {
          _handleDeviceUnregistration(payload);
        } else if (topic.startsWith('devices/') && topic.endsWith('/info')) {
          _handleDeviceInfo(topic, payload);
        } else if (topic.startsWith('devices/') && topic.endsWith('/status')) {
          _handleDeviceStatus(topic, payload);
        }
      } catch (e) {
        debugPrint('DeviceDiscoveryService: Error processing message on topic $topic: $e');
      }
    }
  }

  void _handleDeviceRegistration(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final deviceInfo = DeviceInfo.fromJson(data);
      
      final wasNewDevice = !_discoveredDevices.containsKey(deviceInfo.deviceId);
      _discoveredDevices[deviceInfo.deviceId] = deviceInfo;
      _deviceHeartbeats[deviceInfo.deviceId] = DateTime.now();
      
      debugPrint('DeviceDiscoveryService: Device ${wasNewDevice ? 'registered' : 'updated'}: ${deviceInfo.deviceId}');
      
      if (wasNewDevice) {
        _deviceRegisteredController.add(deviceInfo);
      } else {
        _deviceUpdatedController.add(deviceInfo);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('DeviceDiscoveryService: Error parsing device registration: $e');
    }
  }

  void _handleDeviceHeartbeat(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final deviceId = data['deviceId'] as String;
      
      if (_discoveredDevices.containsKey(deviceId)) {
        _deviceHeartbeats[deviceId] = DateTime.now();
        
        // Update last seen time
        final existingDevice = _discoveredDevices[deviceId]!;
        _discoveredDevices[deviceId] = existingDevice.copyWith(lastSeen: DateTime.now());
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DeviceDiscoveryService: Error parsing heartbeat: $e');
    }
  }

  void _handleDeviceUnregistration(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final deviceId = data['deviceId'] as String;
      
      if (_discoveredDevices.containsKey(deviceId)) {
        _discoveredDevices.remove(deviceId);
        _deviceHeartbeats.remove(deviceId);
        
        debugPrint('DeviceDiscoveryService: Device unregistered: $deviceId');
        _deviceUnregisteredController.add(deviceId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DeviceDiscoveryService: Error parsing device unregistration: $e');
    }
  }

  void _handleDeviceInfo(String topic, String payload) {
    try {
      // Extract device ID from topic: devices/{deviceId}/info
      final deviceId = topic.split('/')[1];
      final data = jsonDecode(payload) as Map<String, dynamic>;
      data['deviceId'] = deviceId; // Ensure deviceId is set
      
      final deviceInfo = DeviceInfo.fromJson(data);
      _discoveredDevices[deviceId] = deviceInfo;
      _deviceHeartbeats[deviceId] = DateTime.now();
      
      _deviceUpdatedController.add(deviceInfo);
      notifyListeners();
    } catch (e) {
      debugPrint('DeviceDiscoveryService: Error parsing device info: $e');
    }
  }

  void _handleDeviceStatus(String topic, String payload) {
    try {
      // Extract device ID from topic: devices/{deviceId}/status
      final deviceId = topic.split('/')[1];
      
      if (_discoveredDevices.containsKey(deviceId)) {
        _deviceHeartbeats[deviceId] = DateTime.now();
        
        final existingDevice = _discoveredDevices[deviceId]!;
        _discoveredDevices[deviceId] = existingDevice.copyWith(lastSeen: DateTime.now());
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DeviceDiscoveryService: Error parsing device status: $e');
    }
  }

  void _startHeartbeatMonitoring() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _checkDeviceHeartbeats();
    });
  }

  void _checkDeviceHeartbeats() {
    final now = DateTime.now();
    final offlineDevices = <String>[];
    
    for (final entry in _deviceHeartbeats.entries) {
      final deviceId = entry.key;
      final lastHeartbeat = entry.value;
      
      // Consider device offline if no heartbeat for 2 minutes
      if (now.difference(lastHeartbeat).inMinutes >= 2) {
        offlineDevices.add(deviceId);
      }
    }
    
    for (final deviceId in offlineDevices) {
      debugPrint('DeviceDiscoveryService: Device went offline: $deviceId');
      _deviceHeartbeats.remove(deviceId);
      // Don't remove from discovered devices - just mark as offline
      // The device might come back online
    }
  }

  /// Request all devices to announce themselves
  void _requestDeviceDiscovery() {
    if (!_isConnected) return;
    
    final discoveryRequest = {
      'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'action': 'announce'
    };
    
    _publishMessage('system/devices/discovery', jsonEncode(discoveryRequest));
  }

  /// Manually trigger device discovery
  Future<void> discoverDevices() async {
    debugPrint('DeviceDiscoveryService: Starting device discovery...');
    _requestDeviceDiscovery();
    
    // Clear existing devices and start fresh
    _discoveredDevices.clear();
    _deviceHeartbeats.clear();
    notifyListeners();
  }

  /// Check if a device is currently online based on heartbeat
  bool isDeviceOnline(String deviceId) {
    final lastHeartbeat = _deviceHeartbeats[deviceId];
    if (lastHeartbeat == null) return false;
    
    return DateTime.now().difference(lastHeartbeat).inMinutes < 2;
  }

  /// Get a specific device info
  DeviceInfo? getDeviceInfo(String deviceId) {
    return _discoveredDevices[deviceId];
  }

  /// Get all online devices
  List<DeviceInfo> getOnlineDevices() {
    return _discoveredDevices.values
        .where((device) => isDeviceOnline(device.deviceId))
        .toList();
  }

  /// Get all offline devices
  List<DeviceInfo> getOfflineDevices() {
    return _discoveredDevices.values
        .where((device) => !isDeviceOnline(device.deviceId))
        .toList();
  }

  void _publishMessage(String topic, String message) {
    if (!_isConnected) return;
    
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _discoveryTimer?.cancel();
    _deviceRegisteredController.close();
    _deviceUnregisteredController.close();
    _deviceUpdatedController.close();
    _client.disconnect();
    super.dispose();
  }
}
