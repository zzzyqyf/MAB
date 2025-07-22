import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  print('🔍 Testing ESP32_001 message subscription...');
  print('===============================================');
  
  await subscribeToESP32Messages();
}

Future<void> subscribeToESP32Messages() async {
  try {
    final client = MqttServerClient('broker.mqtt.cool', 'SubscriberTest_${DateTime.now().millisecondsSinceEpoch}');
    
    client.port = 1883;
    client.secure = false;
    client.logging(on: true);
    client.keepAlivePeriod = 30;
    client.autoReconnect = false;
    client.connectTimeoutPeriod = 5000;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    
    client.onConnected = () {
      print('✅ Subscriber connected successfully!');
    };
    
    client.onDisconnected = () {
      print('❌ Subscriber disconnected');
    };
    
    print('🔌 Connecting subscriber...');
    await client.connect();
    
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('✅ Connected! Subscribing to ESP32_001 topics...');
      
      // Subscribe to all ESP32_001 topics
      final topics = [
        'devices/ESP32_001/status',
        'devices/ESP32_001/sensors/temperature',
        'devices/ESP32_001/sensors/humidity',
        'devices/ESP32_001/sensors/lights',
        'devices/ESP32_001/sensors/bluelight',
        'devices/ESP32_001/sensors/co2',
        'devices/ESP32_001/sensors/moisture',
      ];
      
      for (String topic in topics) {
        client.subscribe(topic, MqttQos.atLeastOnce);
        print('📥 Subscribed to: $topic');
      }
      
      print('');
      print('👂 Listening for messages for 30 seconds...');
      print('💡 Now run your mosquitto_pub commands in another terminal!');
      print('');
      
      // Listen for messages
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (var message in messages) {
          final topic = message.topic;
          final payload = MqttPublishPayload.bytesToStringAsString(
            (message.payload as MqttPublishMessage).payload.message
          );
          
          final emoji = _getTopicEmoji(topic);
          print('📨 RECEIVED: $topic → "$payload" $emoji');
        }
      });
      
      // Wait for messages
      await Future.delayed(const Duration(seconds: 30));
      
      print('⏰ Timeout reached. If no messages were received, the published data may have expired.');
      client.disconnect();
      
    } else {
      print('❌ Failed to connect subscriber');
    }
    
  } catch (e) {
    print('❌ Subscription test failed: $e');
  }
}

String _getTopicEmoji(String topic) {
  if (topic.contains('temperature')) return '🌡️';
  if (topic.contains('humidity')) return '💧';
  if (topic.contains('lights')) return '💡';
  if (topic.contains('moisture')) return '🌱';
  if (topic.contains('status')) return '📶';
  return '📊';
}
