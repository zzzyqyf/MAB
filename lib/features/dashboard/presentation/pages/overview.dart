import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

// Shared imports
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/widgets/Navbar.dart';

// Project imports
import '../../../device_management/presentation/viewmodels/deviceManager.dart';
import '../../../../main.dart';
import '../../../profile/presentation/pages/ProfilePage.dart';
import '../../../notifications/presentation/pages/notification.dart';

// Widget imports
import '../widgets/device_header.dart';
import '../widgets/phase_selector.dart';
import '../widgets/sensor_readings_list.dart';

// Model imports
import '../models/mushroom_phase.dart';

class TentPage extends StatefulWidget {
  final String id; // Unique device ID
  final String name; // Unique device name

  TentPage({required this.id, required this.name});

  @override
  _TentPageState createState() => _TentPageState();
}

class _TentPageState extends State<TentPage> {
  int _selectedIndex = 0;
  MushroomPhase _currentPhase = MushroomPhase.spawnRun; // Default phase

  final List<Widget> _pages = [
    const ProfilePage(),
    const NotificationPage(),
    const MyApp(),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentPhase();
  }

  void _loadCurrentPhase() {
    final deviceManager = Provider.of<DeviceManager>(context, listen: false);
    final device = deviceManager.devices.firstWhere(
      (d) => d['id'] == widget.id,
      orElse: () => <String, dynamic>{},
    );
    
    if (device.isNotEmpty && device['cultivationPhase'] != null) {
      // Convert string back to enum
      final phaseString = device['cultivationPhase'] as String;
      switch (phaseString) {
        case 'Spawn Run':
          _currentPhase = MushroomPhase.spawnRun;
          break;
        case 'Primordia Initiation':
          _currentPhase = MushroomPhase.primordia;
          break;
        case 'Fruiting':
          _currentPhase = MushroomPhase.fruiting;
          break;
        case 'Post-Harvest Recovery':
          _currentPhase = MushroomPhase.postHarvest;
          break;
        default:
          _currentPhase = MushroomPhase.spawnRun;
      }
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

  void _updatePhase(MushroomPhase newPhase) {
    setState(() {
      _currentPhase = newPhase;
    });
    
    // Save to DeviceManager/local storage
    final deviceManager = Provider.of<DeviceManager>(context, listen: false);
    final phaseName = phaseThresholds[newPhase]!.name;
    deviceManager.updateDeviceCultivationPhase(widget.id, phaseName);
    
    TextToSpeech.speak('Phase changed to $phaseName');
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
                    currentPhase: _currentPhase,
                  ),
                  
                  SizedBox(height: AppDimensions.spacing32),
                  
                  SizedBox(height: AppDimensions.spacing16),
                  
                  // Phase selector
                  PhaseSelector(
                    currentPhase: _currentPhase,
                    onPhaseChanged: _updatePhase,
                  ),
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