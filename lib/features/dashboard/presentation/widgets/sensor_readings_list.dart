import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

// Shared imports
import '../../../../shared/services/TextToSpeech.dart';

// Project imports
import '../../../device_management/presentation/widgets/TempVsTimeGraph.dart';
import '../../../device_management/presentation/widgets/HumVsTimeGraph.dart';
import '../../../device_management/presentation/widgets/LightVsTimeGraph.dart';
import '../../../device_management/presentation/widgets/MoistureVsTimeGraph.dart';

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
    debugPrint('🎨 UI: Building SensorReadingsList for $deviceId');
    debugPrint('📊 UI: Current sensor data: $sensorData');
    
    final sensorStatusService = SensorStatusService(currentPhase);

    return Column(
      children: [
        SensorReadingCard(
          title: 'Humidity',
          value: _formatValue(sensorData['humidity'], 1),
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
          value: _formatValue(sensorData['lightState'], 0),
          unit: 'lux',
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
          title: 'Blue Light Intensity',
          value: _formatValue(sensorData['blueLightState'], 0),
          unit: 'lux',
          icon: Icons.wb_sunny,
          iconColor: Colors.blue,
          status: sensorStatusService.getSensorStatusText('bluelight', sensorData['blueLightState']),
          statusColor: sensorStatusService.getSensorStatusColor('bluelight', sensorData['blueLightState']),
          onDoubleTap: () {
            TextToSpeech.speak('Opening Blue Light Intensity details');
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
          title: 'CO2 Level',
          value: _formatValue(sensorData['co2Level'], 0),
          unit: 'ppm',
          icon: FontAwesomeIcons.smog,
          iconColor: Colors.grey[600]!,
          status: sensorStatusService.getSensorStatusText('co2', sensorData['co2Level']),
          statusColor: sensorStatusService.getSensorStatusColor('co2', sensorData['co2Level']),
          onDoubleTap: () {
            TextToSpeech.speak('Opening CO2 Level details');
            // TODO: Create CO2VsTimeGraph when needed
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LightVsTimeGraph(deviceId: deviceId), // Temporary placeholder
              ),
            );
          },
        ),
        SizedBox(height: AppDimensions.spacing12),
        SensorReadingCard(
          title: 'Temperature',
          value: _formatValue(sensorData['temperature'], 1),
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
          value: _formatValue(sensorData['moisture'], 1),
          unit: '%',
          icon: Icons.water_sharp,
          iconColor: AppColors.waterLevel,
          status: sensorStatusService.getSensorStatusText('water', sensorData['moisture']),
          statusColor: sensorStatusService.getSensorStatusColor('water', sensorData['moisture']),
          onDoubleTap: () {
            TextToSpeech.speak('Opening Water Level details');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MoistureVsTimeGraph(deviceId: deviceId),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatValue(dynamic value, int decimals) {
    if (value == null) return '--';
    if (value is num) {
      return value.toStringAsFixed(decimals);
    }
    return value.toString();
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
}
