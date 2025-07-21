import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService extends ChangeNotifier {
  final String mqttBroker = 'localhost'; // Changed from 'broker.mqtt.cool'
  final int mqttPort = 1883;
  late MqttServerClient client;

  final String id;
  double? temperature;
  double? humidity;
  int? lightState;
  double? moisture; // Add moisture support

  final Map<String, DateTime> _lastReceivedTimestamps = {};
  final Map<String, bool> _dataReceivedMap = {};

  final Function(double?, double?, int?, double?) onDataReceived; // Updated signature
  final Function(String id, String newStatus) onDeviceConnectionStatusChange;

  Timer? _dataCheckTimer;

  MqttService({
    required this.id,
    required this.onDataReceived,
    required this.onDeviceConnectionStatusChange,
  });

  Future<void> setupMqttClient() async {
    client = MqttServerClient(mqttBroker, '');
    client.port = mqttPort;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
    //client
        .withClientIdentifier('FlutterClient_$id')
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
      print('Connected to local MQTT broker');
      subscribeToTopics();
    } else {
      print('Failed to connect to local MQTT broker');
    }
  }

  void subscribeToTopics() {
    client.subscribe('esp32/temperature', MqttQos.atLeastOnce);
    client.subscribe('esp32/humidity', MqttQos.atLeastOnce);
    client.subscribe('esp32/lights', MqttQos.atLeastOnce);
    client.subscribe('esp32/moisture', MqttQos.atLeastOnce); // Add moisture

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      print('Received on topic ${c[0].topic}: $message'); // Add debug logging

      if (c[0].topic == 'esp32/temperature') {
        temperature = double.tryParse(message);
      } else if (c[0].topic == 'esp32/humidity') {
        humidity = double.tryParse(message);
      } else if (c[0].topic == 'esp32/lights') {
        lightState = int.tryParse(message);
      } else if (c[0].topic == 'esp32/moisture') { // Add moisture handling
        moisture = double.tryParse(message);
      }

      _lastReceivedTimestamps[id] = DateTime.now();
      _dataReceivedMap[id] = true;
      onDataReceived(temperature, humidity, lightState, moisture); // Include moisture

      notifyListeners(); // Notify listeners when data is updated
    });

    _dataCheckTimer = Timer.periodic(const Duration(seconds: 5), checkDataReception);
  }

  bool isDataReceived(String deviceId) {
    final lastDataTime = _lastReceivedTimestamps[deviceId];
    if (lastDataTime == null) return false;
    return DateTime.now().difference(lastDataTime).inSeconds <= 20;
  }

  void checkDataReception(Timer timer) {
    final isDataReceivedFlag = isDataReceived(id);
    onDeviceConnectionStatusChange(id, isDataReceivedFlag ? 'online' : 'offline');
    notifyListeners(); // Notify listeners about connection status change
  }

  void resetDataReceived(String deviceId) {
    _dataReceivedMap[deviceId] = false;
  }

  void onConnected() {
    print('Connected to local MQTT broker.');
  }

  void onDisconnected() {
    print('Disconnected from local MQTT broker.');
  }

  @override
  void dispose() {
    _dataCheckTimer?.cancel();
    client.disconnect();
    super.dispose();
  }
}
