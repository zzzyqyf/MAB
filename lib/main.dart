import 'dart:async';

import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_application_final/Navbar.dart';
import 'package:flutter_application_final/mqttTests/MQTT.dart';
import 'package:flutter_application_final/mqttservice.dart';
import 'package:flutter_application_final/one.dart';
import 'package:flutter_application_final/overview.dart';
import 'package:flutter_application_final/registerFour.dart';
import 'package:flutter_application_final/three.dart';
import 'package:flutter_application_final/two.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'aTent.dart';
import 'test.dart';

void main() async{

  
  // Initialize Hive
  await Hive.initFlutter();

  // Open the Hive box before using it
  await Hive.openBox('deviceBox');  // Open your box here
  runApp(
    DevicePreview(
      enabled: true, // Enable the device preview for testing
      builder: (context) => ChangeNotifierProvider(
        create: (_) => DeviceManager(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true, // Enable media query for responsiveness
      builder: DevicePreview.appBuilder, // Wraps the app with DevicePreview
      locale: DevicePreview.locale(context), // Supports locale changes in DevicePreview
      title: 'PlantCare Hubs',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // Track the selected index

  // Define pages to navigate to
  final List<Widget> _pages = [
    Register4Widget(id: '',),
    TentPage(id: '',),
    AddDevicePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update selected index
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _pages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context); // Get screen dimensions

    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: const AlignmentDirectional(0, -0.9),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                  0,
                  mediaQuery.size.height * 0.06, // Responsive top padding
                  0,
                  0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PlantCare Hubs',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: mediaQuery.size.width * 0.07, // Responsive font size
                      letterSpacing: 0.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              10, mediaQuery.size.height * 0.15, 0, 5),
            child: Consumer<DeviceManager>(
              builder: (context, deviceManager, child) {
                // Ensure that the device box is loaded and available
                if (deviceManager.deviceBox == null) {
                  return Center(child: CircularProgressIndicator()); // Wait for initialization
                }

                if (deviceManager.devices.isEmpty) {
                  return Center(child: Text('Please add a device.'));
                }

                return GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two columns
                    crossAxisSpacing: mediaQuery.size.width * 0.01, // Horizontal spacing
                    mainAxisSpacing: mediaQuery.size.height * 0.001, // Vertical spacing
                  ),
                  itemCount: deviceManager.devices.length,
                  itemBuilder: (context, index) {
                    var device = deviceManager.devices[index];
                    return Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(0, mediaQuery.size.height * 0.02, 10, 0),
                      child: TentCard(
                        tentName: device['name'],
                        icon: Icons.portable_wifi_off,
                        iconColor: Colors.green,
                        status: device['status'],
                        name: device['name'],
                
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TentPage(id: device['id'] ?? ''),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
class DeviceManager extends ChangeNotifier {
  Box? _deviceBox;
  MqttService? _mqttService;

  final Map<String, Timer> _inactivityTimers = {}; // Track inactivity timers for each device

  Box? get deviceBox => _deviceBox;

  List<Map<String, dynamic>> get devices {
    if (_deviceBox != null && _deviceBox!.isOpen) {
      return _deviceBox!.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  DeviceManager() {
    _initHive();
  }

  Future<void> _initHive() async {
  await Hive.initFlutter();
  _deviceBox = await Hive.openBox('devices');

  // Ensure the devices' statuses are loaded correctly
  if (_deviceBox != null) {
    for (var device in _deviceBox!.values) {
      final deviceId = device['id'];
      final status = device['status'] ?? 'offline';
      onDeviceConnectionStatusChange(deviceId, status); 
            _startPeriodicStatusCheck(deviceId); // Start checking the status periodically
// Update status
    }
  }

  notifyListeners();
}


  void _initMqtt(String deviceId) {
    _mqttService = MqttService(
      id: deviceId,
      onDataReceived: (temperature, humidity, lightState) {
        print("Data received: Temp=$temperature, Humidity=$humidity, Light=$lightState");

        // Check if the device was previously offline, and if so, mark it online
        final device = _deviceBox?.get(deviceId);
        if (device != null && device['status'] == 'offline') {
          onDeviceConnectionStatusChange(deviceId, 'online');
        }

      },
      onDeviceConnectionStatusChange: (deviceId, isOnline) {
        onDeviceConnectionStatusChange(deviceId, isOnline ? 'online' : 'offline');
      }, //onConnectionStatusChange: (isConnected) {  },
    );
    _mqttService?.setupMqttClient();
  }

  void onDeviceConnectionStatusChange(String deviceId, String newStatus) {
    final device = _deviceBox?.get(deviceId);

    if (device != null && device['status'] != newStatus) {
      device['status'] = newStatus;
      _deviceBox?.put(deviceId, device);
      notifyListeners();
    }
  }

  void addDevice(String name) {
    final deviceId = DateTime.now().toString();
      final initialName = name.isEmpty ? 'Unnamed Device' : name; // Set a default name if empty

    final device = {
      'id': deviceId,
      'name': initialName,
      'status': 'connecting', // Initial intermediate status
    };
    _deviceBox?.put(deviceId, device);
    notifyListeners();

    _initMqtt(deviceId);

    // Start a timeout for connecting status
    Timer(Duration(seconds: 10), () {
    final device = _deviceBox?.get(deviceId);
    if (device != null && device['status'] == 'connecting') {
      // If the device is still connecting after 10 seconds, check if data was received
      // If data is received after this timeout, mark it as online
      if (_mqttService?.isDataReceived(deviceId) ?? false) { // Assuming a method `isDataReceived` to check if data was received
        onDeviceConnectionStatusChange(deviceId, 'online');
      } else {
        onDeviceConnectionStatusChange(deviceId, 'offline');
             _startPeriodicStatusCheck(deviceId);
 // Mark as offline if not connected within 10 seconds
      }
    }
  });
  }

  void updateDeviceName(String deviceId, String newName) {
  final device = _deviceBox?.get(deviceId); // Retrieve the device by its ID
  if (device != null) {
    device['name'] = newName; // Update the name
    _deviceBox?.put(deviceId, device); // Save the updated device back in the storage
    notifyListeners(); // Notify listeners about the update
  }
}



void _startPeriodicStatusCheck(String deviceId) {
  int retryCount = 0; // Track the number of retries

  _inactivityTimers[deviceId] = Timer.periodic(Duration(seconds: 10), (timer) {
    final device = _deviceBox?.get(deviceId);

    if (device != null) {
      final currentStatus = device['status'];
      final isDataReceived = _mqttService?.isDataReceived(deviceId) ?? false;

      if (currentStatus == 'offline') {
        print("Device $deviceId is still offline. Checking again in 10 seconds.");
                  print(isDataReceived);

        retryCount++;

        if (isDataReceived) {
          // Data received, mark the device as online
          onDeviceConnectionStatusChange(deviceId, 'online');
          retryCount = 0; // Reset retry count
        } else if (retryCount >= 5) {
          print("Device $deviceId has been offline for too long. Taking action.");
          retryCount = 0; // Reset after action
        }
      } else if (currentStatus == 'online') {
        print("Device $deviceId is online. Continuing to monitor.");
                  print(isDataReceived);


        if (!isDataReceived) {
          // No data received, mark the device as offline
          onDeviceConnectionStatusChange(deviceId, 'offline');
        }

        retryCount = 0; 
                _mqttService?.resetDataReceived(deviceId); // Reset flag after processing
// Reset retry count since the device is online
      }
    } else {
      print("Device not found: $deviceId");
      timer.cancel(); // Stop monitoring if the device is not found
    }
  });
}

  void stopPeriodicStatusCheck(String deviceId) {
    // Cancel the periodic timer when the device is no longer needed for checking
    _inactivityTimers[deviceId]?.cancel();
  }

  Map<String, dynamic>? getDeviceById(String id) {
    return _deviceBox?.get(id);
  }

  List<Map<String, dynamic>> getAllDevices() {
    if (_deviceBox == null) return [];
    return _deviceBox!.values.cast<Map<String, dynamic>>().toList();
  }

  void removeDeviceById(String id) {
    _inactivityTimers[id]?.cancel(); // Cancel the timer for the removed device
    _inactivityTimers.remove(id);

    _deviceBox?.delete(id);
    notifyListeners();
  }

  void removeDevice(String id) {
    removeDeviceById(id); // Call the unified remove logic
  }
}


class TentCard extends StatelessWidget {
  final String tentName;
  final IconData icon;
  final Color iconColor;
  final String status;
  final String name;
  final VoidCallback onTap;

  const TentCard({
    Key? key,
    required this.tentName,
    required this.icon,
    required this.iconColor,
    required this.status,
    required this.name,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);

    // Define icon and color based on the status
    IconData statusIcon;
    Color statusIconColor;

    switch (status) {
      case 'online':
        statusIcon = Icons.check_circle;
        statusIconColor = Colors.green;
        break;
      case 'offline':
        statusIcon = Icons.error;
        statusIconColor = Colors.red;
        break;
      case 'connecting':
      default:
        statusIcon = Icons.sync;
        statusIconColor = Colors.orange;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: mediaQuery.size.width * 0.46,
        height: mediaQuery.size.width * 0.46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 6, 94, 135),
              Color.fromARGB(255, 84, 90, 95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Align(
              alignment: const AlignmentDirectional(-0.40, -0.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    color: statusIconColor,
                    size: mediaQuery.size.width * 0.05,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: mediaQuery.size.width * 0.05,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: const AlignmentDirectional(-0.09, 0.11),
              child: Icon(
                icon,
                color: iconColor,
                size: mediaQuery.size.width * 0.09,
              ),
            ),
            Align(
              alignment: const AlignmentDirectional(-0.09, 0.63),
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: mediaQuery.size.width * 0.06,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
