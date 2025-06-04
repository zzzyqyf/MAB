/*

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class Register4Widgets extends StatefulWidget {
  @override
  _Register4WidgetsState createState() => _Register4WidgetsState();
}

class _Register4WidgetsState extends State<Register4Widgets> {
  final String mqttBroker = 'broker.mqtt.cool';
  final int mqttPort = 1883;
  late MqttServerClient client;

  double? temperature;
  double? humidity;
  int? lightState;

  @override
  void initState() {
    super.initState();
    setupMqttClient();
  }

  // Step 1: Initialize and configure the MQTT client
  Future<void> setupMqttClient() async {
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
    } else {
      print('Failed to connect to MQTT broker');
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
      setState(() {
        if (c[0].topic == 'esp32/temperature') {
          temperature = double.tryParse(message);
          print('Temperature updated to: $temperature °C');
        } else if (c[0].topic == 'esp32/humidity') {
          humidity = double.tryParse(message);
          print('Humidity updated to: $humidity %');
        } else if (c[0].topic == 'esp32/light') {
          lightState = int.tryParse(message);
          print('Light State updated to: ${lightState == 1 ? 'High' : 'Low'}');
        }
      });
    });
  }

  // Callbacks for connection state
  void onConnected() {
    print('Connected to MQTT broker.');
  }

  void onDisconnected() {
    print('Disconnected from the MQTT broker.');
  }

  // Publish message to a control topic
  void sendMessage(String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage('esp32/control', MqttQos.exactlyOnce, builder.payload!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ESP32 Control & Monitor')),
      body: Column(
        children: [
          Text('Temperature: ${temperature ?? 'Loading...'} °C'),
          Text('Humidity: ${humidity ?? 'Loading...'} %'),
          Text('Light State: ${lightState == 1 ? 'High' : 'Low'}'),

          // Toggle LEDs
          ElevatedButton(
            onPressed: () => sendMessage("LED_ON"),
            child: Text("Turn LED On"),
          ),
          ElevatedButton(
            onPressed: () => sendMessage("LED_OFF"),
            child: Text("Turn LED Off"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }
}
*/