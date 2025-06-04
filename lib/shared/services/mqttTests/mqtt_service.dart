import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

class MqttService {
  final client = MqttServerClient('192.168.137.115', 'flutter_client');
  Function(String)? onMessage;

  Future<void> connect() async {
    client.port = 5528;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean();
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      client.disconnect();
    }

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final payload =
          (c![0].payload as MqttPublishMessage).payload.message;
      final message = String.fromCharCodes(payload);
      if (onMessage != null) {
        onMessage!(message);
      }
    });

    subscribe("esp32/sensor");
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
  }

  void onDisconnected() {
    print('Disconnected');
  }

  void disconnect() {
    client.disconnect();
  }
}
