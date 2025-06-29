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
              const SizedBox(height: 24),              ElevatedButton.icon(
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
                    await TextToSpeech.speak("Device ${device['name']} is ${device['status']}${device['sensorStatus'].isNotEmpty ? ' with ${device['sensorStatus']}' : ''}");
                  },
                  child: TentCard(
                    icon: Icons.eco,
                    status: device['status'],
                    name: device['name'],
                    sensorStatus: device['sensorStatus'],
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

class TentCard extends StatelessWidget {
  final IconData icon;
  final String status;
  final String name;
  final VoidCallback onDoubleTap;
  final String sensorStatus;

  const TentCard({
    Key? key,
    required this.icon,
    required this.status,
    required this.name,
    required this.onDoubleTap,
    required this.sensorStatus
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    // Define icon and color based on the status
    IconData statusIcon;
    Color statusIconColor;
    Color cardColor;

    switch (status) {
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
      label: 'Device $name is $status with $sensorStatus',
      hint: 'Double tap to view device details',
      child: GestureDetector(
        onDoubleTap: onDoubleTap,
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
                    name,
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
              
              // Sensor status indicator
              if (sensorStatus.isNotEmpty)
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
                      sensorStatus,
                      style: TextStyle(
                        fontSize: mediaQuery.size.width * 0.03,
                        fontWeight: FontWeight.w500,
                        color: statusIconColor,
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