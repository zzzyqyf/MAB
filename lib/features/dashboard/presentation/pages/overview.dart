import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

// Shared imports
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/widgets/Navbar.dart';
import '../../../../shared/services/alarm_service.dart';

// Project imports
import '../../../device_management/presentation/viewmodels/deviceManager.dart';
import '../../../../main.dart';
import '../../../profile/presentation/pages/ProfilePage.dart';
import '../../../notifications/presentation/pages/notification.dart';

// Widget imports
import '../widgets/device_header.dart';
import '../widgets/sensor_readings_list.dart';
import '../services/mode_controller_service.dart';
import '../services/sensor_status_service.dart';
import 'package:flutter_application_final/features/dashboard/presentation/widgets/mode_selector_widget.dart';

class TentPage extends StatefulWidget {
  final String id; // Unique device ID
  final String name; // Unique device name

  TentPage({required this.id, required this.name});

  @override
  _TentPageState createState() => _TentPageState();
}

class _TentPageState extends State<TentPage> {
  int _selectedIndex = 0;
  final AlarmService _alarmService = AlarmService();
  late ModeControllerService _modeController;

  final List<Widget> _pages = [
    const ProfilePage(),
    const NotificationPage(),
    const MyApp(),
  ];

  @override
  void initState() {
    super.initState();
    _modeController = ModeControllerService(deviceId: widget.id);
    _modeController.addListener(_checkAlarmConditions);
  }

  @override
  void dispose() {
    _modeController.removeListener(_checkAlarmConditions);
    _alarmService.stopAlarm();
    super.dispose();
  }

  void _checkAlarmConditions() {
    // Will be called when mode changes or sensor data updates
    if (mounted) {
      setState(() {});
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _pages[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceManager = Provider.of<DeviceManager>(context);
    int deviceIndex = deviceManager.devices.indexWhere((d) => d['id'] == widget.id);
    
    // Handle case where device is not found
    if (deviceIndex == -1) {
      return Scaffold(
        appBar: BasePage(
          title: 'Overview',
          showBackButton: true,
        ),
        body: const Center(
          child: Text('Device not found'),
        ),
      );
    }

    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {
        // ✅ Get sensor data for this specific device
        final sensorData = deviceManager.getSensorDataForDeviceId(widget.id);
        
        // Check sensor status for alarm
        final sensorStatusService = SensorStatusService(_modeController.currentMode);
        final humidityStatus = sensorStatusService.getSensorStatusColor('humidity', sensorData['humidity']);
        final temperatureStatus = sensorStatusService.getSensorStatusColor('temperature', sensorData['temperature']);
        final waterStatus = sensorStatusService.getSensorStatusColor('water', sensorData['moisture']);
        
        // Trigger alarm check
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _alarmService.checkSensorAlarm(
            sensorData: sensorData,
            deviceName: widget.name,
            humidityStatus: humidityStatus,
            temperatureStatus: temperatureStatus,
            waterStatus: waterStatus,
          );
        });
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: BasePage(
            title: 'Overview',
            showBackButton: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppDimensions.getResponsivePadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alarm indicator banner (shown when alarm is active)
                  if (_alarmService.isAlarmActive)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🚨 URGENT ALERT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _alarmService.currentAlarmReason ?? 'Critical condition detected',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.volume_off,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              await _alarmService.stopAlarm();
                              setState(() {});
                            },
                            tooltip: 'Mute alarm',
                          ),
                        ],
                      ),
                    ),
                  
                  // Header with device name and settings
                  DeviceHeader(
                    deviceName: widget.name,
                    deviceId: widget.id,
                  ),
                  
                  SizedBox(height: AppDimensions.spacing16),
                  
                  // Sensor readings list
                  SensorReadingsList(
                    deviceId: widget.id,
                    sensorData: sensorData,
                  ),
                  
                  SizedBox(height: AppDimensions.spacing32),
                  
                  // Mode selector with timer control
                  ModeSelectorWidget(deviceId: widget.id),
                  
                  SizedBox(height: AppDimensions.spacing16),
                ],
              ),
            ),
          ),
          bottomNavigationBar: CustomNavbar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        );
      },
    );
  }
}