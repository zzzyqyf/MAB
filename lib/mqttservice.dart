import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String mqttBroker = 'broker.mqtt.cool';
  final int mqttPort = 1883;
  late MqttServerClient client;

  final String id; // Unique device ID

  double? temperature;
  double? humidity;
  int? lightState;

  // Tracking the last received time for each device
  final Map<String, DateTime> _lastReceivedTimestamps = {};
  final Map<String, bool> _dataReceivedMap = {};

  // Callback to notify the UI about new data
  final Function(double?, double?, int?) onDataReceived;

  // Callback to notify about device's status (online/offline)
  final Function(String, bool) onDeviceConnectionStatusChange;

  Timer? _dataCheckTimer; 
  // Timer for periodic checks

  MqttService({
    required this.id,
    required this.onDataReceived,
    required this.onDeviceConnectionStatusChange,
  });

  // Initialize and configure the MQTT client
  Future<void> setupMqttClient() async {
    client = MqttServerClient(mqttBroker, '');
    client.port = mqttPort;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('FlutterClient_$id')
        .withWillTopic('willtopic')
        .withWillMessage('Device $id disconnected unexpectedly')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Connection exception: $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Connected to MQTT broker');
      subscribeToTopics();
    } else {
      print('Failed to connect to MQTT broker');
    }
  }

  // Subscribe to necessary topics for receiving data
  void subscribeToTopics() {
    client.subscribe('esp32/temperature', MqttQos.atLeastOnce);
    client.subscribe('esp32/humidity', MqttQos.atLeastOnce);
    client.subscribe('esp32/light', MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (c[0].topic == 'esp32/temperature') {
        temperature = double.tryParse(message);
      } else if (c[0].topic == 'esp32/humidity') {
        humidity = double.tryParse(message);
      } else if (c[0].topic == 'esp32/light') {
        lightState = int.tryParse(message);
      }

      // Update data received timestamp for the device
      _lastReceivedTimestamps[id] = DateTime.now();

      // Notify the UI with the new data
      onDataReceived(temperature, humidity, lightState);
      _dataReceivedMap[id] = true;
    });

    // Start periodic data check every 5 seconds
    _dataCheckTimer = Timer.periodic(Duration(seconds: 5), _checkDataReception);
  }

  // Check if data was received within the last X seconds
  bool isDataReceived(String deviceId) {
    final lastDataTime = _lastReceivedTimestamps[deviceId];
    if (lastDataTime == null) return false;

    final now = DateTime.now();
    return now.difference(lastDataTime).inSeconds <= 10; 
    // Adjust timeout as needed
  }

  // Method to be called periodically
  void _checkDataReception(Timer timer) {
    final isDataReceivedFlag = isDataReceived(id);
    print("Data received status for device $id: $isDataReceivedFlag");

    if (!isDataReceivedFlag) {
      // Handle logic when no data is received
      print("No data received for device $id in the last 10 seconds");
    } else {
      // Handle logic when data is received
      print("Data received for device $id");
    }
  }
  

  // Reset the data received state for the specified device
  void resetDataReceived(String deviceId) {
    _dataReceivedMap[deviceId] = false; // Reset the flag when needed
  }

  // Callbacks for connection state
  void onConnected() {
    print('Connected to MQTT broker.');
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker.');
  }

  // Dispose and clean up resources
  void dispose() {
    _dataCheckTimer?.cancel(); // Cancel the periodic timer
    client.disconnect();
  }
}

