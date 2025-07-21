import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  print('🧪 Testing simple MQTT connection...');
  print('=====================================');
  
  await testSimpleMqttConnection();
}

Future<void> testSimpleMqttConnection() async {
  try {
    final client = MqttServerClient('broker.mqtt.cool', 'SimpleTestClient_${DateTime.now().millisecondsSinceEpoch}');
    
    // Configure client for insecure connection
    client.port = 1883;
    client.secure = false;
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.autoReconnect = false; // Disable for testing
    client.connectTimeoutPeriod = 5000; // 5 seconds
    
    print('🔌 Client configured:');
    print('   📍 Broker: ${client.server}:${client.port}');
    print('   🔒 Secure: ${client.secure}');
    print('   🆔 Client ID: ${client.clientIdentifier}');
    
    // Set up connection message
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    
    // Set up callbacks
    client.onConnected = () {
      print('✅ Connected successfully!');
    };
    
    client.onDisconnected = () {
      print('❌ Disconnected');
    };
    
    print('🔌 Attempting to connect...');
    await client.connect();
    
    // Wait for connection
    int attempts = 0;
    const maxAttempts = 10; // 5 seconds total
    
    while (attempts < maxAttempts) {
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('✅ Connection established!');
        print('📊 Connection status: ${client.connectionStatus?.state}');
        
        // Test publishing a message
        print('📤 Publishing test message...');
        final builder = MqttClientPayloadBuilder();
        builder.addString('Hello from Flutter!');
        client.publishMessage('test/flutter', MqttQos.atLeastOnce, builder.payload!);
        
        await Future.delayed(const Duration(seconds: 2));
        
        print('🔌 Disconnecting...');
        client.disconnect();
        
        print('🎉 Test completed successfully!');
        return;
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
      print('⏳ Waiting for connection... (${attempts * 0.5}s)');
    }
    
    print('❌ Connection timeout after ${maxAttempts * 0.5} seconds');
    print('📊 Final connection status: ${client.connectionStatus?.state}');
    print('📊 Connection return code: ${client.connectionStatus?.returnCode}');
    
  } catch (e) {
    print('❌ Test failed with error: $e');
    print('💡 Error type: ${e.runtimeType}');
  }
}
