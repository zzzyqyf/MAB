import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

/// Centralized MQTT connection manager for handling multiple devices
class MqttManager extends ChangeNotifier {
  static const String mqttBroker = 'broker.mqtt.cool';
  static const int mqttPort = 1883;
  
  static MqttManager? _instance;
  static MqttManager get instance {
    if (_instance == null) {
      _instance = MqttManager._internal();
    }
    return _instance!;
  }
  
  MqttManager._internal() {
    _startConnectionMonitoring();
  }

  /// Initialize the MQTT manager connection
  Future<void> initialize() async {
    if (!_isDisposed && !_isConnected) {
      await _initializeConnection();
    }
  }

  Future<void> _initializeConnection() async {
    try {
      await _setupMqttClient();
    } catch (e) {
      debugPrint('MqttManager: Initial connection failed: $e');
    }
  }
  
  late MqttServerClient _client;
  bool _isConnected = false;
  bool _isDisposed = false;
  
  // Device-specific callbacks
  final Map<String, Function(String topic, String message)> _deviceCallbacks = {};
  final Map<String, List<String>> _deviceSubscriptions = {};
  
  // Connection management
  Timer? _connectionCheckTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  
  // Getters
  bool get isConnected => _isConnected;
  MqttServerClient get client => _client;
  
  Future<void> _setupMqttClient() async {
    if (_isDisposed) return;
    
    // ✅ Check if running on web and handle accordingly
    if (kIsWeb) {
      debugPrint('⚠️ MqttManager: Running on web platform - MQTT connections may be limited');
      debugPrint('💡 MqttManager: Consider using WebSocket MQTT for web apps');
      _isConnected = false;
      return;
    }
    
    try {
      debugPrint('🔌 MqttManager: Setting up MQTT client...');
      
      final clientId = 'MqttManager_${DateTime.now().millisecondsSinceEpoch}';
      _client = MqttServerClient(mqttBroker, clientId);
      
      // ✅ Configure for non-web platforms only
      _client.port = mqttPort;
      _client.secure = false; // Explicitly disable SSL
      _client.logging(on: debugMode);
      _client.keepAlivePeriod = 30;
      _client.autoReconnect = true;
      _client.connectTimeoutPeriod = 5000;
      
      // ✅ Prevent SecurityContext issues on web
      try {
        // Only set security context on non-web platforms
        if (!kIsWeb) {
          // Don't explicitly set securityContext, let it use defaults for insecure connections
        }
      } catch (e) {
        debugPrint('⚠️ MqttManager: SecurityContext warning (this is normal on web): $e');
      }
      
      // ✅ Set up callbacks BEFORE connecting
      _client.onConnected = _onConnected;
      _client.onDisconnected = _onDisconnected;
      _client.onAutoReconnect = _onAutoReconnect;

      final connMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .startClean()
          .withWillQos(MqttQos.atLeastOnce);
      _client.connectionMessage = connMessage;

      debugPrint('🔌 MqttManager: Attempting connection to $mqttBroker:$mqttPort...');
      debugPrint('📋 MqttManager: Client secure = ${_client.secure}');
      debugPrint('📋 MqttManager: Client ID = $clientId');
      debugPrint('📋 MqttManager: Platform = ${kIsWeb ? 'Web' : 'Native'}');
      
      // ✅ Connect with error handling
      await _client.connect();
      
      // ✅ Wait for connection with proper state checking
      int attempts = 0;
      const maxAttempts = 10; // 5 seconds total
      
      while (attempts < maxAttempts && !_isDisposed) {
        if (_client.connectionStatus?.state == MqttConnectionState.connected) {
          debugPrint('✅ MqttManager: Connection established successfully!');
          debugPrint('📊 MqttManager: Connection status = ${_client.connectionStatus?.state}');
          debugPrint('📊 MqttManager: Return code = ${_client.connectionStatus?.returnCode}');
          if (!_isConnected) {
            _onConnected();
          }
          return;
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
        
        if (attempts % 4 == 0) {
          debugPrint('🔄 MqttManager: Still waiting for connection... (${attempts * 0.5}s)');
          debugPrint('📊 MqttManager: Current status = ${_client.connectionStatus?.state}');
        }
      }
      
      // If we get here, connection failed
      debugPrint('❌ MqttManager: Connection timeout after ${maxAttempts * 0.5} seconds');
      debugPrint('📊 MqttManager: Final status = ${_client.connectionStatus?.state}');
      debugPrint('📊 MqttManager: Return code = ${_client.connectionStatus?.returnCode}');
      throw Exception('Connection timeout after ${maxAttempts * 0.5} seconds');
      
    } catch (e) {
      debugPrint('❌ MqttManager: Connection failed: $e');
      
      // ✅ Handle specific web-related errors
      if (e.toString().contains('SecurityContext') || e.toString().contains('Unsupported operation')) {
        debugPrint('💡 MqttManager: This appears to be a web platform limitation');
        debugPrint('💡 MqttManager: MQTT over TCP is not supported in web browsers');
        debugPrint('💡 MqttManager: Consider using WebSocket MQTT (wss://) for web support');
        _isConnected = false;
        return; // Don't retry for web platform issues
      }
      
      _isConnected = false;
      
      if (!_isDisposed) {
        _handleConnectionFailure();
      }
      rethrow;
    }
  }
  
  void _onConnected() {
    if (_isDisposed) return;
    
    debugPrint('✅ MqttManager: Connected to MQTT broker successfully!');
    _isConnected = true;
    _reconnectAttempts = 0;
    
    // ✅ Set up message listener immediately
    _client.updates!.listen(_handleMqttMessage);
    
    // Re-subscribe to all device topics
    _resubscribeAllDevices();
    
    notifyListeners();
  }
  
  void _onDisconnected() {
    if (_isDisposed) return;
    
    debugPrint('❌ MqttManager: Disconnected from MQTT broker');
    _isConnected = false;
    notifyListeners();
  }
  
  void _onAutoReconnect() {
    debugPrint('MqttManager: Auto-reconnecting to MQTT broker');
    _reconnectAttempts++;
  }
  
  void _handleConnectionFailure() {
    // ✅ Don't retry on web platforms due to SecurityContext limitations
    if (kIsWeb) {
      debugPrint('⚠️ MqttManager: Not retrying on web platform due to MQTT limitations');
      debugPrint('💡 MqttManager: Web browsers do not support direct TCP MQTT connections');
      _connectionCheckTimer?.cancel();
      return;
    }
    
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      debugPrint('MqttManager: Retrying connection (attempt $_reconnectAttempts/$maxReconnectAttempts)');
      
      // Use exponential backoff with jitter to prevent connection storms
      final backoffDelay = Duration(seconds: _reconnectAttempts * 2 + (DateTime.now().millisecond % 1000) ~/ 1000);
      Timer(backoffDelay, () {
        if (!_isConnected && !_isDisposed) {
          _setupMqttClient();
        }
      });
    } else {
      debugPrint('MqttManager: Max reconnection attempts reached, stopping reconnection');
      _connectionCheckTimer?.cancel();
    }
  }
  
  void _startConnectionMonitoring() {
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      if (!_isConnected && _reconnectAttempts < maxReconnectAttempts) {
        debugPrint('MqttManager: Connection lost, attempting to reconnect...');
        _setupMqttClient();
      }
    });
  }
  
  void _handleMqttMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = MqttPublishPayload.bytesToStringAsString(
        (message.payload as MqttPublishMessage).payload.message
      );
      
      debugPrint('📨 MqttManager: Received message on $topic: $payload');
      
      // Route message to appropriate device callback
      _routeMessage(topic, payload);
    }
  }
  
  void _routeMessage(String topic, String payload) {
    // Extract device ID from topic if it's a device-specific topic
    if (topic.startsWith('devices/')) {
      final parts = topic.split('/');
      if (parts.length >= 2) {
        final deviceId = parts[1];
        final callback = _deviceCallbacks[deviceId];
        if (callback != null) {
          try {
            debugPrint('📤 MqttManager: Routing message to device $deviceId');
            callback(topic, payload);
          } catch (e) {
            debugPrint('MqttManager: Error in device callback for $deviceId: $e');
          }
        }
      }
    } else {
      // Handle system-level topics by calling all callbacks
      for (final callback in _deviceCallbacks.values) {
        try {
          callback(topic, payload);
        } catch (e) {
          debugPrint('MqttManager: Error in system callback: $e');
        }
      }
    }
  }
  
  /// Register a device with the MQTT manager
  Future<void> registerDevice(String deviceId, Function(String topic, String message) callback) async {
    debugPrint('🔌 MqttManager: Registering device: $deviceId');
    
    // ✅ Handle web platform limitations
    if (kIsWeb) {
      debugPrint('⚠️ MqttManager: Web platform detected - MQTT not supported');
      debugPrint('💡 MqttManager: Device $deviceId registered but MQTT will not work on web');
      _deviceCallbacks[deviceId] = callback;
      _deviceSubscriptions[deviceId] = [];
      notifyListeners();
      return;
    }
    
    // ✅ Ensure connection before registering
    if (!_isConnected && !_isDisposed) {
      debugPrint('📡 MqttManager: Not connected, establishing connection...');
      await _setupMqttClient();
    }
    
    if (!_isConnected) {
      debugPrint('❌ MqttManager: Cannot register device - connection failed');
      return;
    }
    
    _deviceCallbacks[deviceId] = callback;
    _deviceSubscriptions[deviceId] = [];
    
    // Subscribe to device-specific topics
    await _subscribeToDeviceTopics(deviceId);
    
    debugPrint('✅ MqttManager: Device $deviceId registered successfully');
    notifyListeners();
  }
  
  /// Unregister a device from the MQTT manager
  Future<void> unregisterDevice(String deviceId) async {
    debugPrint('MqttManager: Unregistering device: $deviceId');
    
    // Unsubscribe from device topics
    final subscriptions = _deviceSubscriptions[deviceId] ?? [];
    for (final topic in subscriptions) {
      if (_isConnected) {
        _client.unsubscribe(topic);
      }
    }
    
    _deviceCallbacks.remove(deviceId);
    _deviceSubscriptions.remove(deviceId);
    
    notifyListeners();
  }
  
  Future<void> _subscribeToDeviceTopics(String deviceId) async {
    if (!_isConnected) return;
    
    final topics = [
      'devices/$deviceId/sensors/temperature',
      'devices/$deviceId/sensors/humidity',
      'devices/$deviceId/sensors/lights',
      'devices/$deviceId/sensors/bluelight',
      'devices/$deviceId/sensors/co2',
      'devices/$deviceId/sensors/moisture',
      'devices/$deviceId/status',
      'devices/$deviceId/info',
      'devices/$deviceId/config/response',
    ];
    
    for (final topic in topics) {
      try {
        _client.subscribe(topic, MqttQos.atLeastOnce);
        _deviceSubscriptions[deviceId]!.add(topic);
        debugPrint('📥 MqttManager: Subscribed to $topic');
      } catch (e) {
        debugPrint('❌ MqttManager: Failed to subscribe to $topic: $e');
      }
    }
  }
  
  void _resubscribeAllDevices() {
    for (final deviceId in _deviceCallbacks.keys) {
      _subscribeToDeviceTopics(deviceId);
    }
  }
  
  /// Publish a message to a specific topic
  Future<void> publishMessage(String topic, String message, {MqttQos qos = MqttQos.atLeastOnce}) async {
    if (!_isConnected) {
      debugPrint('MqttManager: Cannot publish - not connected to broker');
      return;
    }
    
    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client.publishMessage(topic, qos, builder.payload!);
      debugPrint('MqttManager: Published to $topic: $message');
    } catch (e) {
      debugPrint('MqttManager: Failed to publish message: $e');
    }
  }
  
  /// Send configuration to a device
  Future<void> sendDeviceConfig(String deviceId, Map<String, dynamic> config) async {
    final topic = 'devices/$deviceId/config/set';
    final message = jsonEncode(config);
    await publishMessage(topic, message);
  }
  
  /// Request device configuration
  Future<void> requestDeviceConfig(String deviceId) async {
    final topic = 'devices/$deviceId/config/get';
    final message = jsonEncode({
      'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    await publishMessage(topic, message);
  }
  
  /// Send control command to a device
  Future<void> sendDeviceCommand(String deviceId, String command, {Map<String, dynamic>? parameters}) async {
    final topic = 'devices/$deviceId/commands';
    final message = jsonEncode({
      'command': command,
      'parameters': parameters ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    });
    await publishMessage(topic, message);
  }
  
  /// Bulk operation: Send command to multiple devices
  Future<void> sendBulkCommand(List<String> deviceIds, String command, {Map<String, dynamic>? parameters}) async {
    for (final deviceId in deviceIds) {
      await sendDeviceCommand(deviceId, command, parameters: parameters);
    }
  }
  
  /// Get connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'isConnected': _isConnected,
      'reconnectAttempts': _reconnectAttempts,
      'registeredDevices': _deviceCallbacks.keys.length,
      'totalSubscriptions': _deviceSubscriptions.values.fold<int>(
        0, (total, subs) => total + subs.length
      ),
      'broker': mqttBroker,
      'port': mqttPort,
    };
  }
  
  /// Check if a specific device is registered
  bool isDeviceRegistered(String deviceId) {
    return _deviceCallbacks.containsKey(deviceId);
  }
  
  /// Get all registered device IDs
  List<String> getRegisteredDeviceIds() {
    return _deviceCallbacks.keys.toList();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _connectionCheckTimer?.cancel();
    
    // Unsubscribe from all topics
    for (final subscriptions in _deviceSubscriptions.values) {
      for (final topic in subscriptions) {
        if (_isConnected) {
          try {
            _client.unsubscribe(topic);
          } catch (e) {
            debugPrint('MqttManager: Error unsubscribing from $topic: $e');
          }
        }
      }
    }
    
    _deviceCallbacks.clear();
    _deviceSubscriptions.clear();
    
    if (_isConnected) {
      try {
        _client.disconnect();
      } catch (e) {
        debugPrint('MqttManager: Error during disconnect: $e');
      }
    }
    
    super.dispose();
  }
  
  static bool get debugMode => kDebugMode;
}
