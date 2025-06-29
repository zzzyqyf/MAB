import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

// Shared imports
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/widgets/Navbar.dart';

// Project imports
import '../../../device_management/presentation/widgets/TempVsTimeGraph.dart';
import '../../../device_management/presentation/widgets/HumVsTimeGraph.dart';
import '../../../device_management/presentation/widgets/LightVsTimeGraph.dart';
import '../../../device_management/presentation/viewmodels/deviceManager.dart';
import '../../../profile/presentation/pages/ProfilePage.dart';
import '../../../notifications/presentation/pages/notification.dart';
import '../../../registration/presentation/pages/registerOne.dart';
import '../../../profile/presentation/pages/setting.dart';
import '../../../../main.dart';

class TentPage extends StatefulWidget {
  final String id; // Unique device ID
  final String name; // Unique device name

  TentPage({required this.id, required this.name});

  @override
  _TentPageState createState() => _TentPageState();
}

class _TentPageState extends State<TentPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ProfilePage(),      // Index 0: Profile
    const Register2Widget(),  // Index 1: Add Device (Registration)
    const NotificationPage(), // Index 2: Notifications
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushReplacement(
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
          onBackPressed: () {
            // Navigate back to main Dashboard page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyHomePage(title: 'PlantCare Hubs')),
            );
          },
        ),
        body: const Center(
          child: Text('Device not found'),
        ),
      );
    }

    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {
        final sensorData = deviceManager.sensorData;
        var device = deviceManager.devices[deviceIndex];
        
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: BasePage(
            title: 'Overview',
            showBackButton: true,
            onBackPressed: () {
              // Navigate back to main Dashboard page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage(title: 'PlantCare Hubs')),
              );
            },
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppDimensions.getResponsivePadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with device name and settings button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                            color: AppColors.onBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.settings_sharp,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TentSettingsWidget(deviceId: widget.id),
                            ),
                          );
                        },
                        tooltip: 'Device Settings',
                        semanticLabel: 'Open device settings',
                      ),
                    ],
                  ),
                  
                  SizedBox(height: AppDimensions.spacing32),
                  
                  // Sensor data section - Compact layout
                  Text(
                    'Sensor Readings',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.spacing16),
                  
                  // Compact sensor readings list
                  Column(
                    children: [
                      _buildCompactSensorRow(
                        context,
                        title: 'Humidity',
                        value: '${sensorData['humidity'] ?? '--'}',
                        unit: '%',
                        icon: Icons.water_drop,
                        iconColor: AppColors.humidity,
                        status: device['sensorStatus'] == 'low Humidity' ? 'Low' : 'Normal',
                        onDoubleTap: () {
                          TextToSpeech.speak('Opening Humidity details');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HumVsTimeGraph(deviceId: widget.id),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: AppDimensions.spacing12),
                      _buildCompactSensorRow(
                        context,
                        title: 'Light Intensity',
                        value: '${sensorData['lightState'] ?? '--'}',
                        unit: '%',
                        icon: Icons.lightbulb_outline,
                        iconColor: AppColors.lightIntensity,
                        status: device['sensorStatus'] == 'high lightIntensity' ? 'High' : 'Normal',
                        onDoubleTap: () {
                          TextToSpeech.speak('Opening Light Intensity details');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LightVsTimeGraph(deviceId: widget.id),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: AppDimensions.spacing12),
                      _buildCompactSensorRow(
                        context,
                        title: 'Temperature',
                        value: '${sensorData['temperature'] ?? '--'}',
                        unit: '°C',
                        icon: FontAwesomeIcons.temperatureFull,
                        iconColor: _getTemperatureColor(sensorData['temperature']),
                        status: device['sensorStatus'] == 'High Temperture' ? 'High' : 'Normal',
                        onDoubleTap: () {
                          TextToSpeech.speak('Opening Temperature details');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TempVsTimeGraph(deviceId: widget.id),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: AppDimensions.spacing12),
                      _buildCompactSensorRow(
                        context,
                        title: 'Water Level',
                        value: '50',
                        unit: '%',
                        icon: Icons.water_sharp,
                        iconColor: AppColors.waterLevel,
                        status: device['sensorStatus'] == 'low waterLevel' ? 'Low' : 'Normal',
                        onDoubleTap: () {
                          TextToSpeech.speak('Opening Water Level details');
                          _showWaterLevelDialog(context);
                        },
                      ),
                    ],
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

  Widget _buildCompactSensorRow(
    BuildContext context, {
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required String status,
    VoidCallback? onDoubleTap,
  }) {
    // Determine status color
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'low':
        statusColor = AppColors.warning;
        break;
      case 'high':
        statusColor = AppColors.error;
        break;
      case 'normal':
      default:
        statusColor = AppColors.success;
        break;
    }

    return Semantics(
      label: '$title: $value $unit, Status: $status. Double tap for details.',
      child: GestureDetector(
        onTap: () {
          // Single tap triggers TTS
          TextToSpeech.speak('$title: $value $unit, Status: $status');
        },
        onDoubleTap: onDoubleTap,
        child: Container(
          height: 110, // Increased height to prevent overflow
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingSmall, // Reduced horizontal padding to give more space
            vertical: AppDimensions.paddingSmall, // Less vertical padding
          ),
          margin: EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: statusColor.withOpacity(0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // First row: Icon + Sensor Name
              Row(
                children: [
                  // Icon - compact and clean
                  Container(
                    width: 36,
                    height: 36,
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  
                  SizedBox(width: AppDimensions.spacing12),
                  
                  // Sensor name - full width available
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Second row: Value + Status Badge with optimized spacing
              Padding(
                padding: EdgeInsets.only(top: 4), // Small padding to prevent overflow
                child: Row(
                  children: [
                    // Empty space to push elements to the right
                    Spacer(),
                    
                    // Value with unit - right next to status badge
                    Text(
                      '$value$unit',
                      style: AppTextStyles.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18, // Reduced font size to prevent overflow
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Prevent text overflow
                    ),
                    
                    // Minimal space between value and status badge
                    SizedBox(width: 4), // Reduced spacing
                    
                    // Status badge - right next to value with constrained width
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8, // Reduced horizontal padding
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTemperatureColor(dynamic temperature) {
    if (temperature == null) return AppColors.onSurfaceVariant;
    
    final temp = double.tryParse(temperature.toString()) ?? 0.0;
    if (temp < 15) {
      return AppColors.cold;
    } else if (temp > 30) {
      return AppColors.hot;
    } else {
      return AppColors.temperature;
    }
  }

  void _showWaterLevelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Water Level Details',
            style: AppTextStyles.textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Level: 50%',
                style: AppTextStyles.textTheme.bodyLarge,
              ),
              SizedBox(height: AppDimensions.spacing8),
              Text(
                'Status: Normal',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                ),
              ),
              SizedBox(height: AppDimensions.spacing8),
              Text(
                'Last refilled: 2 days ago',
                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            AppButton(
              text: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              type: AppButtonType.secondary,
              size: AppButtonSize.small,
            ),
          ],
        );
      },
    );
  }
}