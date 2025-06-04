/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DeviceManager(),
      child: const MyApp(),
    ),
  );
}

// Application Root
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Device Manager',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
     // home: const HomePage(),
    );
  }
}

// Device Manager (State Management with Provider



class DeviceManager extends ChangeNotifier {
  late Box _deviceBox;

  // Return list of devices as Map<String, dynamic>
  List<Map<String, dynamic>> get devices =>
      _deviceBox.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();

  DeviceManager() {
    _initHive();
  }

  Future<void> _initHive() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Open the box for dynamic type storage
    _deviceBox = await Hive.openBox('devices');
    notifyListeners();
  }

  void addDevice(String name) {
    // Create a device object
    final device = {
      'id': DateTime.now().toString(),
      'name': name,
      'status': 'Good',
    };

    // Save the device into the Hive box
    _deviceBox.put(device['id'], device);
    notifyListeners();
  }

  void removeDevice(String id) {
    // Remove the device by its ID
    _deviceBox.delete(id);
    notifyListeners();
  }
}

*/
