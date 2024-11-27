import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'main.dart';

class MqttService {
  final String mqttBroker = 'broker.mqtt.cool';
  final int mqttPort = 1883;
  late MqttServerClient client;

  double? temperature;
  double? humidity;
  int? lightState;

  // Callback to notify the UI about new data
  final Function(double?, double?, int?) onDataReceived;

  // Callback to notify about device connection status changes
  final Function(String, bool) onDeviceConnectionStatusChange;

  MqttService({
    required this.onDataReceived,
    required this.onDeviceConnectionStatusChange, // Add this line
  });

  // Step 1: Initialize and configure the MQTT client
  Future<void> setupMqttClient(String deviceId) async {
    client = MqttServerClient(mqttBroker, '');
    client.port = mqttPort;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('FlutterClient')
        .withWillTopic('willtopic') // Used for last will message
        .withWillMessage('Device disconnected unexpectedly')
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
      // Update device status to online
      onDeviceConnectionStatusChange(deviceId, true);
    } else {
      print('Failed to connect to MQTT broker');
      // Update device status to offline
      onDeviceConnectionStatusChange(deviceId, false);
    }
  }

  // Step 2: Subscribe to necessary topics after confirming connection
  void subscribeToTopics() {
    client.subscribe('esp32/temperature', MqttQos.atLeastOnce);
    client.subscribe('esp32/humidity', MqttQos.atLeastOnce);
    client.subscribe('esp32/light', MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      // Update state variables based on topic
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
    // Here you should pass the correct device ID and true for online status
    //onDeviceConnectionStatusChange('deviceId', true);  // Example device ID
  }

  void onDisconnected() {
    print('Disconnected from the MQTT broker.');
    // Here you should pass the correct device ID and false for offline status
   // onDeviceConnectionStatusChange('device_123', false);  // Example device ID
  }

  // Publish message to a control topic
  void sendMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage('esp32/control', MqttQos.exactlyOnce, builder.payload!);
  }

  void dispose() {
    client.disconnect();
  }
}
