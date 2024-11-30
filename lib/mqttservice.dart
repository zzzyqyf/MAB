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

  // Callback to notify the UI about new data
  final Function(double?, double?, int?) onDataReceived;

  // Callback to notify about device connection status changes
  final Function(bool) onConnectionStatusChange;

  MqttService({
    required this.id,
    required this.onDataReceived,
    required this.onConnectionStatusChange, required Null Function(dynamic String, dynamic bool) onDeviceConnectionStatusChange,
  });

  // Step 1: Initialize and configure the MQTT client
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
    }

    // Check if connected, then subscribe to topics
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Connected to MQTT broker');
      subscribeToTopics();
      onConnectionStatusChange(true); // Notify UI about connection status
    } else {
      print('Failed to connect to MQTT broker');
      onConnectionStatusChange(false); // Notify UI about connection failure
    }
  }

  // Step 2: Subscribe to necessary topics
  void subscribeToTopics() {
    client.subscribe('esp32/temperature', MqttQos.atLeastOnce);
    client.subscribe('esp32/humidity', MqttQos.atLeastOnce);
    client.subscribe('esp32/light', MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (c[0].topic == 'esp32/temperature') {
        temperature = double.tryParse(message);
      } else if (c[0].topic == 'esp32/humidity') {
        humidity = double.tryParse(message);
      } else if (c[0].topic == 'esp32/light') {
        lightState = int.tryParse(message);
      }

      // Notify the UI with the new data
      onDataReceived(temperature, humidity, lightState);
    });
  }

  // Callbacks for connection state
  void onConnected() {
    print('Connected to MQTT broker.');
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker.');
    onConnectionStatusChange(false); // Notify about disconnection
  }

  void dispose() {
    client.disconnect();
  }
}
