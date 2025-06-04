// filepath: d:\fyp\Backup\MAB\lib\features\dashboard\presentation\pages\overview.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

// Shared imports
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/basePage.dart';
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/widgets/Navbar.dart';

// Project imports
import '../../../device_management/presentation/widgets/TempVsTimeGraph.dart';
import '../../../device_management/presentation/widgets/HumVsTimeGraph.dart';
import '../../../device_management/presentation/widgets/LightVsTimeGraph.dart';
import '../../../device_management/presentation/viewmodels/deviceManager.dart';
import '../../../../main.dart';
import '../../../profile/presentation/pages/ProfilePage.dart';
import '../../../notifications/presentation/pages/notification.dart';
import '../../../profile/presentation/pages/setting.dart';

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
    const ProfilePage(),
    const NotificationPage(),
    const MyApp(),
  ];

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
        final sensorData = deviceManager.sensorData;
        var device = deviceManager.devices[deviceIndex];
        
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                                color: AppColors.onBackground,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: AppDimensions.spacing4),
                            Text(
                              'Device ID: ${widget.id}',
                              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
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
                  
                  // Sensor data grid
                  Text(
                    'Sensor Readings',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      color: AppColors.onBackground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.spacing16),
                  
                  // Grid of sensor cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = AppDimensions.getResponsiveColumns(context);
                      final childAspectRatio = constraints.maxWidth / crossAxisCount > 200 ? 1.2 : 1.1;
                      
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppDimensions.spacing12,
                        mainAxisSpacing: AppDimensions.spacing12,
                        childAspectRatio: childAspectRatio,
                        children: [
                          _buildSensorCard(
                            context,
                            title: 'Humidity',
                            value: '${sensorData['humidity'] ?? '--'}',
                            unit: '%',
                            icon: Icons.water_drop,
                            iconColor: AppColors.humidity,
                            subtitle: device['sensorStatus'] == 'low Humidity' ? 'Low Humidity' : null,
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
                          _buildSensorCard(
                            context,
                            title: 'Light Intensity',
                            value: '${sensorData['lightState'] ?? '--'}',
                            unit: '%',
                            icon: Icons.lightbulb_outline,
                            iconColor: AppColors.lightIntensity,
                            subtitle: device['sensorStatus'] == 'high lightIntensity' ? 'High Light' : null,
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
                          _buildSensorCard(
                            context,
                            title: 'Temperature',
                            value: '${sensorData['temperature'] ?? '--'}',
                            unit: '°C',
                            icon: FontAwesomeIcons.temperatureFull,
                            iconColor: _getTemperatureColor(sensorData['temperature']),
                            subtitle: device['sensorStatus'] == 'High Temperture' ? 'High Temperature' : null,
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
                          _buildSensorCard(
                            context,
                            title: 'Water Level',
                            value: '50',
                            unit: '%',
                            icon: Icons.water_sharp,
                            iconColor: AppColors.waterLevel,
                            subtitle: device['sensorStatus'] == 'low waterLevel' ? 'Low Water' : null,
                            onDoubleTap: () {
                              TextToSpeech.speak('Opening Water Level details');
                              _showWaterLevelDialog(context);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  
                  SizedBox(height: AppDimensions.spacing32),
                  
                  // Device status section
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.device_hub,
                              color: AppColors.primary,
                              size: AppDimensions.iconMedium,
                            ),
                            SizedBox(width: AppDimensions.spacing12),
                            Text(
                              'Device Status',
                              style: AppTextStyles.cardTitle,
                            ),
                          ],
                        ),
                        SizedBox(height: AppDimensions.spacing16),
                        _buildStatusRow('Connection', 'Online', AppColors.online),
                        SizedBox(height: AppDimensions.spacing8),
                        _buildStatusRow('Last Update', 'Just now', AppColors.onSurfaceVariant),
                        SizedBox(height: AppDimensions.spacing8),
                        _buildStatusRow('Battery', '87%', AppColors.success),
                      ],
                    ),
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

  Widget _buildSensorCard(
    BuildContext context, {
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
    String? subtitle,
    VoidCallback? onDoubleTap,
  }) {
    return GestureDetector(
      onTap: () {
        // Single tap triggers TTS
        final subtitleText = subtitle != null ? ': $subtitle' : '';
        TextToSpeech.speak('$title: $value $unit$subtitleText');
      },
      onDoubleTap: onDoubleTap,
      child: SensorCard(
        title: title,
        value: value,
        unit: unit,
        icon: icon,
        iconColor: iconColor,
        subtitle: subtitle,
        semanticLabel: '$title sensor reading: $value $unit${subtitle != null ? ', status: $subtitle' : ''}',
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

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
