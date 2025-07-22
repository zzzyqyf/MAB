import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  final client = MqttServerClient('broker.mqtt.cool', 'QuickCO2Test_${DateTime.now().millisecondsSinceEpoch}');
  client.port = 1883;
  client.secure = false;
  client.logging(on: false);
  
  await client.connect();
  
  if (client.connectionStatus?.state == MqttConnectionState.connected) {
    final builder = MqttClientPayloadBuilder();
    builder.addString('850');
    client.publishMessage('devices/ESP32_001/sensors/co2', MqttQos.atLeastOnce, builder.payload!);
    print('✅ Published CO2: 850 ppm to devices/ESP32_001/sensors/co2');
  } else {
    print('❌ Failed to connect');
  }
  
  await Future.delayed(Duration(seconds: 1));
  client.disconnect();
}
