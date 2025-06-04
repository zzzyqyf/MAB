
/*

import 'package:flutter/material.dart';
import 'MqttTestApp.dart';
//import 'package:flutter_application_final/mqttprovider.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:provider/provider.dart';

class MqttTestWidget extends StatefulWidget {
  @override
  _MqttTestWidgetState createState() => _MqttTestWidgetState();
}

class _MqttTestWidgetState extends State<MqttTestWidget> {
  final String mqttBroker = 'broker.mqtt.cool';
  final int mqttPort = 1883;
  late MqttServerClient client;

  @override
  void initState() {
    super.initState();
    setupMqttClient();
  }

  Future<void> setupMqttClient() async {
    client = MqttServerClient(mqttBroker, '');
    client.port = mqttPort;
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('FlutterClient')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Connection exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Connected to MQTT broker');
      client.subscribe('esp32/temperature', MqttQos.atLeastOnce);
      client.subscribe('esp32/humidity', MqttQos.atLeastOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        if (c[0].topic == 'esp32/temperature') {
          final temperature = double.tryParse(message);
          if (temperature != null) {
            // Update the temperature in the MqttDataProvider
            context.read<MqttDataProvider>().updateTemperature(temperature);
          }
          print('Temperature updated to: $temperature °C');
        } else if (c[0].topic == 'esp32/humidity') {
          final humidity = double.tryParse(message);
          if (humidity != null) {
            // Update the humidity in the MqttDataProvider
            context.read<MqttDataProvider>().updateHumidity(humidity);
          }
          print('Humidity updated to: $humidity %');
        }
      });
    } else {
      print('Failed to connect to MQTT broker');
    }
  }

  void onConnected() {
    print('Connected to MQTT broker.');
  }

  void onDisconnected() {
    print('Disconnected from the MQTT broker.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ESP32 Control & Monitor')),
      body: Consumer<MqttDataProvider>(
        builder: (context, mqttData, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Temperature: ${mqttData.temperature?.toStringAsFixed(1) ?? 'Loading...'} °C'),
              Text('Humidity: ${mqttData.humidity?.toStringAsFixed(1) ?? 'Loading...'} %'),
            ],
          );
        },
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