// import 'dart:async';
// import 'dart:convert';
// import 'package:mqtt_client/mqtt_client.dart';
// import 'package:mqtt_client/mqtt_server_client.dart';

// void main() async {
//   print('🧪 Starting ESP32_001 MQTT Testing...');
//   print('====================================');
  
//   await testESP32_001MQTTFlow();
// }

// Future<void> testESP32_001MQTTFlow() async {
//   try {
//     final client = MqttServerClient('broker.mqtt.cool', 'ESP32_001_TestClient');
//     client.port = 1883;
//     client.logging(on: true);
//     client.keepAlivePeriod = 30;
//     client.autoReconnect = true;
    
//     client.onConnected = () {
//       print('✅ Connected to MQTT broker successfully!');
//     };
    
//     client.onDisconnected = () {
//       print('❌ Disconnected from MQTT broker');
//     };
    
//     final connMessage = MqttConnectMessage()
//         .withClientIdentifier('ESP32_001_TestClient')
//         .startClean()
//         .withWillQos(MqttQos.atLeastOnce);
//     client.connectionMessage = connMessage;
    
//     print('🔌 Connecting to broker.mqtt.cool...');
//     await client.connect();
    
//     if (client.connectionStatus?.state == MqttConnectionState.connected) {
//       print('✅ Connected! Publishing sensor data for ESP32_001...');
      
//       await publishSensorUpdate(client, 'ESP32_001', 'temperature', '25.5');
//       await Future.delayed(const Duration(seconds: 2));
      
//       await publishSensorUpdate(client, 'ESP32_001', 'humidity', '65.2');
//       await Future.delayed(const Duration(seconds: 2));
      
//       await publishSensorUpdate(client, 'ESP32_001', 'lights', '800');
//       await Future.delayed(const Duration(seconds: 2));
      
//       await publishSensorUpdate(client, 'ESP32_001', 'bluelight', '920');
//       await Future.delayed(const Duration(seconds: 2));
      
//       await publishSensorUpdate(client, 'ESP32_001', 'co2', '750');
//       await Future.delayed(const Duration(seconds: 2));
      
//       await publishSensorUpdate(client, 'ESP32_001', 'moisture', '78.3');
//       await Future.delayed(const Duration(seconds: 2));
      
//       await publishSensorUpdate(client, 'ESP32_001', 'status', 'online');
      
//       print('');
//       print('🎯 Test completed! Published data:');
//       print('   🌡️ Temperature: 25.5°C');
//       print('   💧 Humidity: 65.2%');
//       print('   💡 Light: 800 lux');
//       print('   🔵 Blue Light: 920 lux');
//       print('   🌫️ CO2: 750 ppm');
//       print('   🌱 Moisture: 78.3%');
//       print('   📶 Status: online');
//       print('');
//       print('✅ Check your Flutter app - sensor values should update immediately!');
      
//       // Keep publishing every 5 seconds for continuous testing
//       print('');
//       print('🔄 Starting continuous data stream...');
//       for (int i = 0; i < 10; i++) {
//         await Future.delayed(const Duration(seconds: 5));
        
//         final temp = 25.5 + (i * 0.3);
//         final humidity = 65.2 + (i * 1.1);
//         final lights = 800 + (i * 10);
//         final bluelight = 920 + (i * 5);
//         final co2 = 750 + (i * 15);
//         final moisture = 78.3 - (i * 0.5);
        
//         await publishSensorUpdate(client, 'ESP32_001', 'temperature', temp.toStringAsFixed(1));
//         await publishSensorUpdate(client, 'ESP32_001', 'humidity', humidity.toStringAsFixed(1));
//         await publishSensorUpdate(client, 'ESP32_001', 'lights', lights.toString());
//         await publishSensorUpdate(client, 'ESP32_001', 'bluelight', bluelight.toString());
//         await publishSensorUpdate(client, 'ESP32_001', 'co2', co2.toString());
//         await publishSensorUpdate(client, 'ESP32_001', 'moisture', moisture.toStringAsFixed(1));
        
//         print('📊 Update ${i + 1}: Temp=${temp.toStringAsFixed(1)}°C, Humidity=${humidity.toStringAsFixed(1)}%, Light=${lights}lux, CO2=${co2}ppm');
//       }
      
//       client.disconnect();
//       print('');
//       print('🏁 Testing completed successfully!');
      
//     } else {
//       print('❌ Failed to connect. Status: ${client.connectionStatus}');
//     }
    
//   } catch (e) {
//     print('❌ MQTT Test Error: $e');
//   }
// }

// Future<void> publishSensorUpdate(MqttServerClient client, String deviceId, String sensorType, String value, {bool useTimestamp = true}) async {
//   final topic = sensorType == 'status' 
//       ? 'devices/$deviceId/status'
//       : 'devices/$deviceId/sensors/$sensorType';
      
//   final builder = MqttClientPayloadBuilder();
  
//   // Generate ESP32-style timestamp
//   final timestamp = DateTime.now().millisecondsSinceEpoch;
  
//   String payload;
//   if (useTimestamp && sensorType != 'status') {
//     // JSON format with timestamp (simulating ESP32 behavior)
//     final jsonData = {
//       'value': _parseValue(sensorType, value),
//       'timestamp': timestamp,
//     };
//     payload = jsonEncode(jsonData);
//   } else {
//     // Simple value format (for status or backward compatibility)
//     payload = value;
//   }
  
//   builder.addString(payload);
//   client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  
//   final emoji = _getSensorEmoji(sensorType);
//   final unit = _getSensorUnit(sensorType, value);
//   final timestampStr = useTimestamp && sensorType != 'status' 
//       ? ' [${DateTime.fromMillisecondsSinceEpoch(timestamp)}]' 
//       : '';
  
//   print('📤 Published: $topic → $payload $emoji$timestampStr');
// }

// // Helper function to parse value as appropriate type
// dynamic _parseValue(String sensorType, String value) {
//   switch (sensorType) {
//     case 'lights':
//     case 'bluelight':
//     case 'co2':
//       return int.tryParse(value) ?? value;
//     case 'temperature':
//     case 'humidity':
//     case 'moisture':
//       return double.tryParse(value) ?? value;
//     default:
//       return value;
//   }
// }

// String _getSensorEmoji(String sensorType) {
//   switch (sensorType) {
//     case 'temperature': return '🌡️';
//     case 'humidity': return '💧';
//     case 'lights': return '💡';
//     case 'bluelight': return '🔵';
//     case 'co2': return '🌫️';
//     case 'moisture': return '🌱';
//     case 'status': return '📶';
//     default: return '📊';
//   }
// }

// String _getSensorUnit(String sensorType, String value) {
//   switch (sensorType) {
//     case 'temperature': return '°C';
//     case 'humidity': return '%';
//     case 'moisture': return '%';
//     case 'lights': return ' lux';
//     case 'bluelight': return ' lux';
//     case 'co2': return ' ppm';
//     case 'status': return '';
//     default: return '';
//   }
// }
