import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  print('🌫️ Testing CO2 Sensor MQTT Publishing');
  print('====================================');
  
  await publishCO2TestData();
}

Future<void> publishCO2TestData() async {
  try {
    final client = MqttServerClient('broker.mqtt.cool', 'CO2Publisher_${DateTime.now().millisecondsSinceEpoch}');
    
    client.port = 1883;
    client.secure = false;
    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.autoReconnect = false;
    client.connectTimeoutPeriod = 5000;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    
    print('🔌 Connecting to MQTT broker...');
    await client.connect();
    
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('✅ Connected! Publishing CO2 test data...');
      print('');
      
      // CO2 test values (in ppm)
      final co2Values = [
        {'value': '400', 'description': 'Normal outdoor air'},
        {'value': '800', 'description': 'Typical indoor air'},
        {'value': '1200', 'description': 'Stuffy room'},
        {'value': '1800', 'description': 'Poor ventilation'},
        {'value': '3000', 'description': 'Unhealthy levels'},
        {'value': '600', 'description': 'Back to normal'},
      ];
      
      for (final test in co2Values) {
        final topic = 'devices/ESP32_001/sensors/co2';
        final message = test['value']!;
        
        print('🌫️ Publishing CO2: ${message} ppm (${test['description']})');
        
        final builder = MqttClientPayloadBuilder();
        builder.addString(message);
        
        client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
        
        await Future.delayed(Duration(seconds: 2));
      }
      
      print('');
      print('🏁 CO2 sensor testing completed!');
      print('💡 Check your Flutter app to see if CO2 values are displayed');
      
    } else {
      print('❌ Failed to connect to MQTT broker');
    }
    
    await Future.delayed(Duration(seconds: 2));
    client.disconnect();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
