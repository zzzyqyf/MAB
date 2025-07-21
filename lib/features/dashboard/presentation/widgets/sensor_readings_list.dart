import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';

// Shared imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/widgets/app_button.dart';

// Project imports
import '../../../device_management/presentation/widgets/TempVsTimeGraph.dart';
import '../../../device_management/presentation/widgets/HumVsTimeGraph.dart';
import '../../../device_management/presentation/widgets/LightVsTimeGraph.dart';

// Widget imports
import 'sensor_reading_card.dart';

// Model imports
import '../models/mushroom_phase.dart';
import '../services/sensor_status_service.dart';

class SensorReadingsList extends StatelessWidget {
  final String deviceId;
  final Map<String, dynamic> sensorData;
  final MushroomPhase currentPhase;

  const SensorReadingsList({
    Key? key,
    required this.deviceId,
    required this.sensorData,
    required this.currentPhase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sensorStatusService = SensorStatusService(currentPhase);

    return Column(
      children: [
        SensorReadingCard(
          title: 'Humidity',
          value: '${sensorData['humidity'] ?? '--'}',
          unit: '%',
          icon: Icons.water_drop,
          iconColor: AppColors.humidity,
          status: sensorStatusService.getSensorStatusText('humidity', sensorData['humidity']),
          statusColor: sensorStatusService.getSensorStatusColor('humidity', sensorData['humidity']),
          onDoubleTap: () {
            TextToSpeech.speak('Opening Humidity details');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HumVsTimeGraph(deviceId: deviceId),
              ),
            );
          },
        ),
        SizedBox(height: AppDimensions.spacing12),
        SensorReadingCard(
          title: 'Light Intensity',
          value: '${sensorData['lightState'] ?? '--'}',
          unit: '%',
          icon: Icons.lightbulb_outline,
          iconColor: AppColors.lightIntensity,
          status: sensorStatusService.getSensorStatusText('light', sensorData['lightState']),
          statusColor: sensorStatusService.getSensorStatusColor('light', sensorData['lightState']),
          onDoubleTap: () {
            TextToSpeech.speak('Opening Light Intensity details');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LightVsTimeGraph(deviceId: deviceId),
              ),
            );
          },
        ),
        SizedBox(height: AppDimensions.spacing12),
        SensorReadingCard(
          title: 'Temperature',
          value: '${sensorData['temperature'] ?? '--'}',
          unit: '°C',
          icon: FontAwesomeIcons.temperatureFull,
          iconColor: _getTemperatureColor(sensorData['temperature']),
          status: sensorStatusService.getSensorStatusText('temperature', sensorData['temperature']),
          statusColor: sensorStatusService.getSensorStatusColor('temperature', sensorData['temperature']),
          onDoubleTap: () {
            TextToSpeech.speak('Opening Temperature details');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TempVsTimeGraph(deviceId: deviceId),
              ),
            );
          },
        ),
        SizedBox(height: AppDimensions.spacing12),
        SensorReadingCard(
          title: 'Water Level',
          value: '${sensorData['moisture'] ?? '50'}',
          unit: '%',
          icon: Icons.water_sharp,
          iconColor: AppColors.waterLevel,
          status: sensorStatusService.getSensorStatusText('water', sensorData['moisture']),
          statusColor: sensorStatusService.getSensorStatusColor('water', sensorData['moisture']),
          onDoubleTap: () {
            TextToSpeech.speak('Opening Water Level details');
            _showWaterLevelDialog(context);
          },
        ),
      ],
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
