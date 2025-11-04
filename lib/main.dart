import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Core imports
import 'core/constants/firebase_options.dart';
import 'core/theme/app_theme.dart';

// Dependency Injection
import 'injection_container.dart' as di;

// Shared imports
import 'shared/widgets/Navbar.dart';
import 'shared/services/TextToSpeech.dart';

// Feature imports
import 'features/profile/presentation/pages/ProfilePage.dart';
import 'features/device_management/presentation/viewmodels/deviceManager.dart';
import 'features/device_management/presentation/viewmodels/device_view_model.dart';
import 'features/notifications/presentation/pages/notification.dart';
import 'features/dashboard/presentation/pages/overview.dart';
import 'features/dashboard/presentation/services/mode_controller_service.dart';
import 'features/dashboard/presentation/models/mushroom_phase.dart';
import 'features/registration/presentation/pages/registerOne.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notifications
  await initNotifications();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize dependency injection
  await di.init();
  await di.initializeHive();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceManager()),
        ChangeNotifierProvider(create: (_) => di.sl<DeviceViewModel>()),
      ],
      child: MaterialApp(
        // Enhanced accessibility configuration
        home: const MyApp(),
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Apply accessibility scaling and high contrast
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.2, // Larger text for better readability
              boldText: true, // Bolder text for high contrast
            ),
            child: DevicePreview.appBuilder(context, child),
          );
        },
      ),
    ),
  );
}



final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
 const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon'); // match your custom icon name  // App icon

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'PlantCare Hubs'),
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
    const ProfilePage(),      // Index 0: Profile
    const Register2Widget(),  // Index 1: Add Device (Registration)
    const NotificationPage(), // Index 2: Notifications
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update selected index
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _pages[index]),
    );
  }

  // Function to report device issues via TTS
  void _reportDeviceIssues(DeviceManager deviceManager) async {
    if (deviceManager.devices.isEmpty) {
      await TextToSpeech.speak('No devices connected. Please add a device first.');
      return;
    }

    List<String> issues = [];
    Map<String, dynamic> sensorData = deviceManager.sensorData;
    
    for (var device in deviceManager.devices) {
      String deviceName = device['name'] ?? 'Unknown Device';
      String deviceId = device['id'] ?? '';
      String status = device['status'] ?? 'unknown';
      
      // Check device connectivity status
      if (status.toLowerCase() == 'offline') {
        issues.add('$deviceName is offline and not responding');
      } else if (status.toLowerCase() == 'error') {
        issues.add('$deviceName has a connection error');
      }
      
      // Check sensor data for this device if available
      if (sensorData.containsKey(deviceId)) {
        var deviceSensorData = sensorData[deviceId];
        
        // Check temperature (threshold is 32.0°C)
        if (deviceSensorData['temperature'] != null) {
          double temp = deviceSensorData['temperature'].toDouble();
          if (temp > 32.0) {
            issues.add('$deviceName has high temperature at ${temp.toStringAsFixed(1)} degrees Celsius');
          } else if (temp < 10.0) {
            issues.add('$deviceName has low temperature at ${temp.toStringAsFixed(1)} degrees Celsius');
          }
        }
        
        // Check humidity (threshold is 20.0%)
        if (deviceSensorData['humidity'] != null) {
          double humidity = deviceSensorData['humidity'].toDouble();
          if (humidity < 20.0) {
            issues.add('$deviceName has low humidity at ${humidity.toStringAsFixed(1)} percent');
          } else if (humidity > 90.0) {
            issues.add('$deviceName has very high humidity at ${humidity.toStringAsFixed(1)} percent');
          }
        }
        
        // Check light intensity (assuming threshold around 100-1000 lux)
        if (deviceSensorData['light'] != null) {
          double light = deviceSensorData['light'].toDouble();
          if (light < 100.0) {
            issues.add('$deviceName has insufficient light intensity at ${light.toStringAsFixed(0)} lux');
          }
        }
        
        // Check soil moisture or water level (assuming 0-100% range)
        if (deviceSensorData['moisture'] != null) {
          double moisture = deviceSensorData['moisture'].toDouble();
          if (moisture < 30.0) {
            issues.add('$deviceName has low soil moisture at ${moisture.toStringAsFixed(1)} percent');
          }
        }
        
        // Check for any sensor that hasn't been updated recently
        if (deviceSensorData['lastUpdate'] != null) {
          DateTime lastUpdate = DateTime.parse(deviceSensorData['lastUpdate']);
          Duration timeSinceUpdate = DateTime.now().difference(lastUpdate);
          if (timeSinceUpdate.inMinutes > 30) {
            issues.add('$deviceName has not sent sensor data for ${timeSinceUpdate.inMinutes} minutes');
          }
        }
      } else if (status.toLowerCase() == 'online') {
        // Device is online but no sensor data available
        issues.add('$deviceName is online but not sending sensor data');
      }
    }
    
    // Report the issues
    if (issues.isEmpty) {
      await TextToSpeech.speak('All devices are working normally. No issues detected.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ All devices are working normally!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      String report = 'Device issues report: ';
      report += issues.join('. ');
      await TextToSpeech.speak(report);
      
      // Also show a snackbar with the issues
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${issues.length} issue${issues.length != 1 ? 's' : ''}. Check TTS for details.'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Repeat',
            onPressed: () => TextToSpeech.speak(report),
            textColor: Colors.white,
          ),
        ),
      );
    }
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
              child: SizedBox.shrink(), // Remove the Dashboard text completely
            ),
          ),          Padding(
  padding: EdgeInsetsDirectional.fromSTEB(
    16, mediaQuery.size.height * 0.15, 16, 16),
  child: Consumer<DeviceManager>( // Watching DeviceManager for changes
    builder: (context, deviceManager, child) {
      // Ensure that the device box is loaded and available
      if (deviceManager.deviceBox == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading devices...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      }

      // Handle case when there are no devices
      if (deviceManager.devices.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.device_hub_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'No Devices Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first device to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      print('Add Device button pressed'); // Debug print
                      try {
                        // Navigate to device registration page without waiting for TextToSpeech
                        TextToSpeech.speak('Opening device registration'); // Don't await
                        print('Starting navigation'); // Debug print
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Register2Widget(),
                          ),
                        );
                        print('Navigation completed'); // Debug print
                      } catch (e) {
                        print('Error in Add Device button: $e'); // Debug print
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Device'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _reportDeviceIssues(deviceManager);
                    },
                    icon: const Icon(Icons.report_problem_outlined),
                    label: const Text('Report'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }

      // Calculate responsive grid layout
      final crossAxisCount = mediaQuery.size.width > 600 ? 3 : 2;
      final spacing = mediaQuery.size.width * 0.03;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Devices',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${deviceManager.devices.length} device${deviceManager.devices.length != 1 ? 's' : ''} connected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // Report Issues Button
                ElevatedButton.icon(
                  onPressed: () {
                    _reportDeviceIssues(deviceManager);
                  },
                  icon: Icon(
                    Icons.report_problem_outlined,
                    size: 18,
                  ),
                  label: const Text('Report'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          
          // Devices grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 1.0,
              ),
              itemCount: deviceManager.devices.length,
              itemBuilder: (context, index) {
                var device = deviceManager.devices[index];
                print("Device ${device['name']} - Sensor Status: ${device['sensorStatus']}");

                return GestureDetector(
                  onTap: () async {
                    // Trigger text-to-speech on tap
                    await TextToSpeech.speak("Device ${device['name']} is ${device['status']}");
                  },
                  child: TentCard(
                    icon: Icons.eco,
                    status: device['status'],
                    name: device['name'],
                    deviceId: device['id'],
                    onDoubleTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TentPage(id: device['id'], name: device['name']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
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

class TentCard extends StatefulWidget {
  final IconData icon;
  final String status;
  final String name;
  final String deviceId;
  final VoidCallback onDoubleTap;

  const TentCard({
    Key? key,
    required this.icon,
    required this.status,
    required this.name,
    required this.deviceId,
    required this.onDoubleTap,
  }) : super(key: key);

  @override
  State<TentCard> createState() => _TentCardState();
}

class _TentCardState extends State<TentCard> {
  late ModeControllerService _modeController;

  @override
  void initState() {
    super.initState();
    _modeController = ModeControllerService(deviceId: widget.deviceId);
    _modeController.addListener(_onModeChanged);
  }

  void _onModeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _modeController.removeListener(_onModeChanged);
    // Don't dispose singleton
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final currentMode = _modeController.currentMode;
    final modeName = currentMode == CultivationMode.pinning ? 'Pinning' : 'Normal';
    final modeIcon = currentMode == CultivationMode.pinning ? '🍄' : '🌱';

    // Define icon and color based on the status
    IconData statusIcon;
    Color statusIconColor;
    Color cardColor;

    switch (widget.status) {
      case 'online':
        statusIcon = Icons.wifi;
        statusIconColor = Colors.green;
        cardColor = theme.colorScheme.primary;
        break;
      case 'offline':
        statusIcon = Icons.signal_wifi_off;
        statusIconColor = Colors.red;
        cardColor = theme.colorScheme.error;
        break;
      case 'connecting':
      default:
        statusIcon = Icons.sync;
        statusIconColor = Colors.orange;
        cardColor = theme.colorScheme.tertiary;
        break;
    }

    return Semantics(
      label: 'Device ${widget.name} is ${widget.status}, Mode: $modeName',
      hint: 'Double tap to view device details',
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap,
        child: Container(
          width: mediaQuery.size.width * 0.46,
          height: mediaQuery.size.width * 0.46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cardColor.withOpacity(0.9),
                cardColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Status indicator in top right
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusIconColor,
                    size: 20,
                  ),
                ),
              ),
              
              // Device name
              Align(
                alignment: const AlignmentDirectional(0, -0.3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: mediaQuery.size.width * 0.055,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // Device icon
              Align(
                alignment: const AlignmentDirectional(0, 0.3),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: mediaQuery.size.width * 0.08,
                  ),
                ),
              ),
              
              // Mode indicator at bottom
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$modeIcon $modeName',
                    style: TextStyle(
                      fontSize: mediaQuery.size.width * 0.03,
                      fontWeight: FontWeight.w600,
                      color: currentMode == CultivationMode.pinning 
                          ? Colors.orange[700] 
                          : Colors.green[700],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}