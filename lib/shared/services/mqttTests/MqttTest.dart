
/*
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttTest extends StatefulWidget {
  @override
  _MqttTestAppState createState() => _MqttTestAppState();
}

class _MqttTestAppState extends State<MqttTest> {
  late MqttServerClient client;
  String temperature = 'Loading...';
  String humidity = 'Loading...';
  String lights = 'Loading...';

  @override
  void initState() {
    super.initState();
    connectMqtt();
  }

  Future<void> connectMqtt() async {
    client = MqttServerClient('broker.mqtt.cool', '');
    client.port = 1883;
    client.keepAlivePeriod = 20;

    client.onConnected = () {
      print('Connected to MQTT Broker');
      client.subscribe('esp32/temperature', MqttQos.atMostOnce);
      client.subscribe('esp32/humidity', MqttQos.atMostOnce);
      client.subscribe('esp32/lights', MqttQos.atMostOnce);
    };

    client.onDisconnected = () {
      print('Disconnected from MQTT Broker');
    };

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      setState(() {
        if (c[0].topic == 'esp32/temperature') {
          temperature = message;
        } else if (c[0].topic == 'esp32/humidity') {
          humidity = message;
        } else if (c[0].topic == 'esp32/lights') {
          lights = message;
        }
      });

      print('Received message: $message on topic: ${c[0].topic}');
    });
    

    try {
      await client.connect();
    } catch (e) {
      print('MQTT connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MQTT Test')),
      body: Column(
        children: [
          Text('Temperature: $temperature'),
          Text('Humidity: $humidity'),
          Text('Lights: $lights'),
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