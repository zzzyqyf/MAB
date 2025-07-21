import 'dart:io';

void main() async {
  print('🔍 Testing network connectivity to MQTT broker...');
  print('===================================================');
  
  await testMqttConnectivity();
}

Future<void> testMqttConnectivity() async {
  final brokers = [
    'broker.mqtt.cool',
    'test.mosquitto.org',
    'broker.emqx.io',
    'mqtt.eclipseprojects.io',
  ];
  
  const port = 1883;
  
  for (String broker in brokers) {
    print('\n🔗 Testing connection to $broker:$port...');
    
    try {
      // Test DNS resolution first
      print('   🔍 Resolving DNS for $broker...');
      final addresses = await InternetAddress.lookup(broker)
          .timeout(const Duration(seconds: 5));
      
      final ipAddresses = addresses.map((a) => a.address).join(', ');
      print('   ✅ DNS resolution successful: $ipAddresses');
      
      // Test TCP connection
      print('   🔌 Testing TCP connection...');
      final socket = await Socket.connect(broker, port)
          .timeout(const Duration(seconds: 10));
      
      print('   ✅ TCP connection successful to $broker:$port');
      print('   📊 Local address: ${socket.address.address}:${socket.port}');
      print('   📊 Remote address: ${socket.remoteAddress.address}:${socket.remotePort}');
      
      socket.destroy();
      
      // Test basic MQTT handshake
      print('   🤝 Testing MQTT handshake...');
      await testMqttHandshake(broker, port);
      
    } catch (e) {
      print('   ❌ Connection failed: $e');
      _diagnoseConnectionError(e, broker);
    }
  }
  
  print('\n🔍 Network diagnostics completed!');
  print('💡 If all connections failed, check firewall/network settings');
}

Future<void> testMqttHandshake(String broker, int port) async {
  try {
    final socket = await Socket.connect(broker, port)
        .timeout(const Duration(seconds: 10));
    
    // Send MQTT CONNECT packet (simplified)
    final connectPacket = [
      0x10, 0x2C, // Fixed header: CONNECT, remaining length = 44
      0x00, 0x04, 'M'.codeUnitAt(0), 'Q'.codeUnitAt(0), 'T'.codeUnitAt(0), 'T'.codeUnitAt(0), // Protocol name
      0x04, // Protocol level
      0x02, // Connect flags (clean session)
      0x00, 0x3C, // Keep alive = 60 seconds
      0x00, 0x18, // Client ID length = 24
      ...('TestClient_${DateTime.now().millisecondsSinceEpoch}'.substring(0, 24).codeUnits),
    ];
    
    socket.add(connectPacket);
    
    // Wait for CONNACK
    final response = await socket.first.timeout(const Duration(seconds: 5));
    
    if (response.length >= 4 && response[0] == 0x20 && response[3] == 0x00) {
      print('   ✅ MQTT handshake successful!');
    } else {
      print('   ⚠️ MQTT handshake received unexpected response: ${response.map((b) => b.toRadixString(16)).join(' ')}');
    }
    
    socket.destroy();
    
  } catch (e) {
    print('   ⚠️ MQTT handshake failed: $e');
  }
}

void _diagnoseConnectionError(dynamic error, String broker) {
  final errorStr = error.toString().toLowerCase();
  
  if (errorStr.contains('timeout')) {
    print('   💡 Diagnosis: Connection timeout - likely firewall blocking');
  } else if (errorStr.contains('network is unreachable')) {
    print('   💡 Diagnosis: Network unreachable - check internet connection');
  } else if (errorStr.contains('connection refused')) {
    print('   💡 Diagnosis: Connection refused - broker may be down or port blocked');
  } else if (errorStr.contains('host lookup failed')) {
    print('   💡 Diagnosis: DNS resolution failed - check DNS settings');
  } else if (errorStr.contains('socketexception')) {
    print('   💡 Diagnosis: Socket error - likely firewall or network configuration issue');
  } else {
    print('   💡 Diagnosis: Unknown network error - check firewall and network settings');
  }
}
