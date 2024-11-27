import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:provider/provider.dart';

class MqttDataProvider extends ChangeNotifier {
  double? _temperature;
  double? _humidity;

  double? get temperature => _temperature;
  double? get humidity => _humidity;

  set temperature(double? newTemp) {
    _temperature = newTemp;
    notifyListeners();
  }

  set humidity(double? newHumidity) {
    _humidity = newHumidity;
    notifyListeners();
  }

  void updateTemperature(double temperature) {}

  void updateHumidity(double humidity) {}
}

class MqttTestApp extends StatefulWidget {
  @override
  _MqttTestAppState createState() => _MqttTestAppState();
}

class _MqttTestAppState extends State<MqttTestApp> {
  final String broker = 'broker.mqtt.cool';
  final int port = 1883;
  late MqttServerClient client;

  @override
  void initState() {
    super.initState();
    setupMqttClient();
  }

  Future<void> setupMqttClient() async {
    client = MqttServerClient(broker, '');
    client.port = port;
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('FlutterClient')
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMessage;

    try {
      await client.connect();
    } catch (e) {
      print('Connection exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('Connected to MQTT broker');
      client.subscribe('esp32/temperature', MqttQos.atMostOnce);
      client.subscribe('esp32/humidity', MqttQos.atMostOnce);
      client.subscribe('esp32/lightIntensity', MqttQos.atMostOnce);


      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final message =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

        setState(() {
          if (c[0].topic == 'esp32/temperature') {
            double? newTemp = double.tryParse(message);
            if (newTemp != null) {
              Provider.of<MqttDataProvider>(context, listen: false)
                  .temperature = newTemp;
              print('Temperature updated: $newTemp °C');
            }
          } else if (c[0].topic == 'esp32/humidity') {
            double? newHumidity = double.tryParse(message);
            if (newHumidity != null) {
              Provider.of<MqttDataProvider>(context, listen: false)
                  .humidity = newHumidity;
              print('Humidity updated: $newHumidity %');
            }
          }
        });
      });
    } else {
      print('Failed to connect');
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
      appBar: AppBar(title: Text('ESP32 MQTT Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Temperature: ${Provider.of<MqttDataProvider>(context).temperature ?? 'Loading...'} °C'),
            Text('Humidity: ${Provider.of<MqttDataProvider>(context).humidity ?? 'Loading...'} %'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MqttDataProvider(),
      child: MaterialApp(home: MqttTestApp()),
    ),
  );
}