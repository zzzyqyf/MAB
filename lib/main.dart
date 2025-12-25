import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for kReleaseMode
import 'package:device_preview/device_preview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audio_session/audio_session.dart'; // For audio session management

// Core imports
import 'core/constants/firebase_options.dart';
import 'core/theme/app_theme.dart';

// Dependency Injection
import 'injection_container.dart' as di;

// Shared imports
import 'shared/widgets/Navbar.dart';
import 'shared/services/TextToSpeech.dart';
import 'shared/services/mqtt_manager.dart';
import 'shared/services/fcm_service.dart';
import 'shared/services/alarm_service.dart';
import 'shared/widgets/alarm_snooze_dialog.dart';

// Feature imports
import 'features/profile/presentation/pages/ProfilePage.dart';
import 'features/device_management/presentation/viewmodels/deviceManager.dart';
import 'features/device_management/presentation/viewmodels/device_view_model.dart';
import 'features/notifications/presentation/pages/notification.dart';
import 'features/dashboard/presentation/pages/overview.dart';
import 'features/dashboard/presentation/services/mode_controller_service.dart';
import 'features/dashboard/presentation/models/mushroom_phase.dart';
import 'features/registration/presentation/pages/registerOne.dart';
import 'features/authentication/presentation/widgets/auth_wrapper.dart';
import 'features/graph_api/presentation/viewmodels/graph_api_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('🚀 App starting... Release mode: $kReleaseMode');
  
  try {
    // 🔊 Force audio session activation for alarm sounds
    // This fixes audio issues on MIUI, Huawei, Vivo, and other Android variants
    debugPrint('🔊 Configuring audio session...');
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      debugPrint('✅ Audio session activated successfully');
    } catch (e) {
      debugPrint('⚠️ Audio session configuration failed: $e');
      // Continue even if audio session fails - it's not critical for app startup
    }
    
    // Initialize Firebase
    debugPrint('📱 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
    
    // Initialize notifications
    debugPrint('🔔 Initializing notifications...');
    await initNotifications();
    debugPrint('✅ Notifications initialized');
    
    // Initialize timezone for scheduled notifications
    debugPrint('🌍 Initializing timezone...');
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Hong_Kong')); // Adjust to your timezone
    debugPrint('✅ Timezone initialized');
    
    // Initialize Hive
    debugPrint('💾 Initializing Hive...');
    await Hive.initFlutter();
    debugPrint('✅ Hive initialized');
    
    // Initialize dependency injection
    debugPrint('🔧 Initializing dependency injection...');
    await di.init();
    await di.initializeHive();
    debugPrint('✅ Dependency injection initialized');
    
    // Initialize MQTT Manager
    debugPrint('📡 Initializing MQTT Manager...');
    await MqttManager.instance.initialize();
    debugPrint('✅ MQTT Manager initialized');
    
    // Initialize FCM Service
    debugPrint('🔔 Initializing FCM Service...');
    await FcmService().initialize();
    debugPrint('✅ FCM Service initialized');
    
    // Initialize TTS with audio configuration
    debugPrint('🗣️ Initializing Text-to-Speech...');
    await TextToSpeech.initialize();
    debugPrint('✅ TTS initialized');
    
    debugPrint('🎉 All initialization complete, launching app...');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DeviceManager()),
          ChangeNotifierProvider(create: (_) => di.sl<DeviceViewModel>()),
          ChangeNotifierProvider(create: (_) => di.sl<GraphApiViewModel>()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL ERROR during initialization: $e');
    debugPrint('📚 Stack trace: $stackTrace');
    // Show error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



// Global navigator key for accessing context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  debugPrint('🔔 Setting up local notifications with action handlers...');
  
  // Use '@mipmap/ic_launcher' instead of 'app_icon' - this always exists
  const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Default launcher icon

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      debugPrint('📲 Notification action received: ${response.actionId}');
      
      if (response.actionId == 'dismiss') {
        // User clicked "Dismiss" button
        await AlarmService().dismissAlarm();
      } else if (response.actionId == 'snooze') {
        // User clicked "Snooze" button
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          // App is in foreground - show picker dialog
          showDialog(
            context: context,
            builder: (context) => const AlarmSnoozeDialog(),
          );
        } else {
          // App is in background - use default 5 minutes
          await AlarmService().snoozeAlarm(const Duration(minutes: 5));
        }
      }
    },
  );
  
  debugPrint('✅ Notification action handlers set up');
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Set context for FCM service to show dialogs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        FcmService().setContext(context);
      }
    });
    
    return MaterialApp(
      navigatorKey: navigatorKey, // Add global navigator key
      useInheritedMediaQuery: true, // Enable media query for responsiveness
      builder: (context, child) {
        // Apply accessibility scaling
        final mediaQueryData = MediaQuery.of(context).copyWith(
          textScaleFactor: 1.2, // Larger text for better readability
          boldText: true, // Bolder text for high contrast
        );
        
        // Only use DevicePreview in debug mode
        if (kReleaseMode) {
          // Release mode: no DevicePreview
          return MediaQuery(
            data: mediaQueryData,
            child: child!,
          );
        } else {
          // Debug mode: with DevicePreview
          return MediaQuery(
            data: mediaQueryData,
            child: DevicePreview.appBuilder(context, child),
          );
        }
      },
      locale: kReleaseMode ? null : DevicePreview.locale(context), // Only in debug mode
      title: 'PlantCare Hubs',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(), // Use AuthWrapper to handle authentication state
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

  bool _devicesLoaded = false; // Track if devices have been loaded
  String? _lastLoadedUserId; // Track which user's devices were loaded

  @override
  void initState() {
    super.initState();
    print('🚀🚀🚀 MyHomePage initState called!');
    // Load user's devices from Firestore when home page initializes
    _loadUserDevices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if user changed and reload devices if needed
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null && currentUserId != _lastLoadedUserId) {
      print('🔄🔄🔄 User changed, reloading devices for new user: $currentUserId');
      _devicesLoaded = false; // Reset flag to allow reload
      _loadUserDevices();
    }
  }
  
  /// Force reload devices from Firestore (useful after adding/removing devices)
  Future<void> _reloadDevices() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    
    try {
      print('🔄 MyHomePage: Force reloading devices from Firestore...');
      final deviceManager = Provider.of<DeviceManager>(context, listen: false);
      await deviceManager.loadUserDevicesFromFirestore();
      print('✅ MyHomePage: Devices reloaded successfully');
    } catch (e) {
      print('❌ MyHomePage: Error reloading devices: $e');
    }
  }

  /// Load devices for the logged-in user from Firestore
  Future<void> _loadUserDevices() async {
    if (_devicesLoaded) return; // Prevent multiple loads for same user
    
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      print('❌❌❌ No user logged in');
      return;
    }
    
    try {
      print('🔄🔄🔄 MyHomePage: Starting to load user devices from Firestore...');
      final deviceManager = Provider.of<DeviceManager>(context, listen: false);
      await deviceManager.loadUserDevicesFromFirestore();
      print('✅✅✅ MyHomePage: Devices loaded successfully');
      
      setState(() {
        _devicesLoaded = true;
        _lastLoadedUserId = currentUserId; // Remember which user's devices we loaded
      });
    } catch (e) {
      print('❌❌❌ MyHomePage: Error loading user devices: $e');
      setState(() {
        _devicesLoaded = true; // Still mark as loaded to avoid infinite retry
        _lastLoadedUserId = currentUserId;
      });
    }
  }

  
  int _selectedIndex = 0; // Track the selected index

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update selected index
    });
    
    // Create fresh widget instances on navigation
    Widget destination;
    switch (index) {
      case 0:
        destination = const ProfilePage();
        break;
      case 1:
        destination = const Register2Widget();
        break;
      case 2:
        destination = const NotificationPage(); // Fresh instance!
        break;
      default:
        return; // Invalid index
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context); // Get screen dimensions

    return Scaffold(
      body: Stack(
        children: [
          // Show loading indicator while devices are being loaded from Firestore
          if (!_devicesLoaded)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading your devices...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          // Show main content after devices are loaded
          if (_devicesLoaded) ...[
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
              ],
            ),
          ),
          
          // Devices grid with pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reloadDevices,
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
                  final mqttId = device['mqttId'] ?? device['name'] ?? device['id'];
                  // Use sensorStatus to determine online/offline - simpler and more accurate
                  final sensorStatus = device['sensorStatus'] ?? 'no data';
                  final isOnline = sensorStatus == 'online';
                  final displayStatus = isOnline ? 'online' : 'offline';
                  
                  print("Device ${device['name']} - Sensor Status: $sensorStatus -> Display: $displayStatus");

                  return GestureDetector(
                    onTap: () async {
                      // Trigger text-to-speech on tap
                      await TextToSpeech.speak("Device ${device['name']} is $displayStatus");
                    },
                    child: TentCard(
                      icon: Icons.eco,
                      status: displayStatus,
                      name: device['name'],
                      deviceId: device['id'],
                      mqttId: mqttId,
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
          ),
        ],
      );
    },
  ),
), // Close Padding widget
], // Close the if (_devicesLoaded) list
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
  final String mqttId;
  final VoidCallback onDoubleTap;

  const TentCard({
    Key? key,
    required this.icon,
    required this.status,
    required this.name,
    required this.deviceId,
    required this.mqttId,
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
    // Use mqttId for ModeController instead of Firebase deviceId
    _modeController = ModeControllerService(deviceId: widget.mqttId);
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

    // Define icon and color based on the status (only online/offline)
    IconData statusIcon;
    Color statusIconColor;
    Color cardColor;

    if (widget.status == 'online') {
      statusIcon = Icons.wifi;
      statusIconColor = Colors.green;
      cardColor = theme.colorScheme.primary;
    } else {
      // Default to offline for any non-online status
      statusIcon = Icons.signal_wifi_off;
      statusIconColor = Colors.red;
      cardColor = theme.colorScheme.error;
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