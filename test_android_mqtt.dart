import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  print('🧪 Testing MQTT connection with Android permissions...');
  print('=====================================================');
  
  await testMqttWithAndroidConfig();
}

Future<void> testMqttWithAndroidConfig() async {
  try {
    print('📱 Configuring MQTT client for Android...');
    
    final client = MqttServerClient('broker.mqtt.cool', 'AndroidTest_${DateTime.now().millisecondsSinceEpoch}');
    client.port = 1883;
    client.secure = false;
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.autoReconnect = false;
    client.connectTimeoutPeriod = 10000; // Longer timeout for Android
    
    client.onConnected = () {
      print('✅ Android MQTT connected successfully!');
    };
    
    client.onDisconnected = () {
      print('❌ Android MQTT disconnected');
    };
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    
    print('🔌 Attempting Android MQTT connection...');
    print('📋 Broker: ${client.server}:${client.port}');
    print('📋 Secure: ${client.secure}');
    print('📋 Timeout: ${client.connectTimeoutPeriod}ms');
    
    await client.connect();
    
    // Wait longer for Android connection
    int attempts = 0;
    const maxAttempts = 20; // 10 seconds
    
    while (attempts < maxAttempts) {
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        print('✅ Android connection established!');
        
        // Test subscribing to ESP32_001 topics
        print('📥 Subscribing to ESP32_001 topics...');
        client.subscribe('devices/ESP32_001/sensors/temperature', MqttQos.atLeastOnce);
        client.subscribe('devices/ESP32_001/sensors/humidity', MqttQos.atLeastOnce);
        client.subscribe('devices/ESP32_001/sensors/lights', MqttQos.atLeastOnce);
        client.subscribe('devices/ESP32_001/sensors/moisture', MqttQos.atLeastOnce);
        client.subscribe('devices/ESP32_001/status', MqttQos.atLeastOnce);
        
        // Listen for messages
        client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
          for (var message in messages) {
            final topic = message.topic;
            final payload = MqttPublishPayload.bytesToStringAsString(
              (message.payload as MqttPublishMessage).payload.message
            );
            print('📨 Android received: $topic → "$payload"');
          }
        });
        
        // Test publishing
        print('📤 Publishing test data from Android...');
        final builder = MqttClientPayloadBuilder();
        builder.addString('25.5');
        client.publishMessage('devices/ESP32_001/sensors/temperature', MqttQos.atLeastOnce, builder.payload!);
        
        print('👂 Listening for 10 seconds...');
        await Future.delayed(const Duration(seconds: 10));
        
        client.disconnect();
        print('✅ Android MQTT test completed successfully!');
        return;
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
      
      if (attempts % 4 == 0) {
        print('⏳ Android connection attempt ${attempts}/20...');
        print('📊 Status: ${client.connectionStatus?.state}');
      }
    }
    
    print('❌ Android connection timeout');
    print('📊 Final status: ${client.connectionStatus?.state}');
    print('📊 Return code: ${client.connectionStatus?.returnCode}');
    
  } catch (e) {
    print('❌ Android MQTT test failed: $e');
    print('💡 Make sure INTERNET permission is added to AndroidManifest.xml');
  }
}
