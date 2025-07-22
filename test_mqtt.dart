import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  print('Starting MQTT test for ESP32_003...');
  
  // Simulate ESP32_003 device publishing sensor data
  await simulateESP32Device();
}

Future<void> simulateESP32Device() async {
  try {
    final client = MqttServerClient('broker.mqtt.cool', 'ESP32_003_Simulator');
    client.port = 1883;
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.autoReconnect = true;
    
    // Set up connection callbacks
    client.onConnected = () {
      print('✅ ESP32_003 Simulator Connected!');
    };
    
    client.onDisconnected = () {
      print('❌ ESP32_003 Simulator Disconnected');
    };
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('ESP32_003_Simulator')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    
    print('🔌 Connecting ESP32_003 Simulator to broker...');
    await client.connect();
    
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('✅ ESP32_003 Simulator connected successfully!');
      
      // Publish sensor data for ESP32_003
      await publishSensorData(client, 'ESP32_003', 24.5, 58.3, 1, 42.7);
      
      // Keep publishing data every 5 seconds for 30 seconds
      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(seconds: 5));
        final temp = 24.5 + (i * 0.5); // Simulate changing temperature
        final humidity = 58.3 + (i * 1.2); // Simulate changing humidity
        final moisture = 42.7 - (i * 0.8); // Simulate changing moisture
        await publishSensorData(client, 'ESP32_003', temp, humidity, 1, moisture);
      }
      
      client.disconnect();
      print('� ESP32_003 Simulation completed!');
      
    } else {
      print('❌ Failed to connect ESP32_003 Simulator. Status: ${client.connectionStatus}');
    }
    
  } catch (e) {
    print('❌ ESP32_003 Simulation Error: $e');
  }
}

Future<void> publishSensorData(MqttServerClient client, String deviceId, 
    double temperature, double humidity, int lightState, double moisture) async {
  
  final builder = MqttClientPayloadBuilder();
  
  // Publish temperature
  builder.clear();
  builder.addString(temperature.toString());
  client.publishMessage('devices/$deviceId/sensors/temperature', 
      MqttQos.atLeastOnce, builder.payload!);
  print('📤 Published Temperature: ${temperature}°C');
  
  // Publish humidity
  builder.clear();
  builder.addString(humidity.toString());
  client.publishMessage('devices/$deviceId/sensors/humidity', 
      MqttQos.atLeastOnce, builder.payload!);
  print('📤 Published Humidity: ${humidity}%');
  
  // Publish light state
  builder.clear();
  builder.addString(lightState.toString());
  client.publishMessage('devices/$deviceId/sensors/lights', 
      MqttQos.atLeastOnce, builder.payload!);
  print('📤 Published Light State: ${lightState == 1 ? "ON" : "OFF"}');
  
  // Publish moisture
  builder.clear();
  builder.addString(moisture.toString());
  client.publishMessage('devices/$deviceId/sensors/moisture', 
      MqttQos.atLeastOnce, builder.payload!);
  print('� Published Moisture: ${moisture}%');
  
  // Publish device status
  builder.clear();
  builder.addString('online');
  client.publishMessage('devices/$deviceId/status', 
      MqttQos.atLeastOnce, builder.payload!);
  print('📤 Published Status: online');
  
  print('---');
}
