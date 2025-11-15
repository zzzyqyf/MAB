import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Core imports
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';

// Shared imports
// import '../../../../shared/services/TextToSpeech.dart'; // 🚫 Disabled temporarily

// Project imports
// import '../../../device_management/presentation/widgets/TempVsTimeGraph.dart'; // 🚫 Disabled temporarily
// import '../../../device_management/presentation/widgets/HumVsTimeGraph.dart'; // 🚫 Disabled temporarily
// import '../../../device_management/presentation/widgets/MoistureVsTimeGraph.dart'; // 🚫 Disabled temporarily

// Widget imports
import 'sensor_reading_card.dart';

// Service imports
import '../services/sensor_status_service.dart';
import '../services/mode_controller_service.dart';

class SensorReadingsList extends StatefulWidget {
  final String deviceId;
  final Map<String, dynamic> sensorData;

  const SensorReadingsList({
    Key? key,
    required this.deviceId,
    required this.sensorData,
  }) : super(key: key);

  @override
  State<SensorReadingsList> createState() => _SensorReadingsListState();
}

class _SensorReadingsListState extends State<SensorReadingsList> {
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
    // Don't dispose singleton - it's shared across widgets
    // _modeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 UI: Building SensorReadingsList for ${widget.deviceId}');
    debugPrint('📊 UI: Current sensor data: ${widget.sensorData}');
    debugPrint('🔧 UI: Current mode: ${_modeController.currentMode}');
    
    final sensorStatusService = SensorStatusService(_modeController.currentMode);

    return Column(
      children: [
        SensorReadingCard(
          title: 'Humidity',
          value: _formatValue(widget.sensorData['humidity'], 1),
          unit: '%',
          icon: Icons.water_drop,
          iconColor: AppColors.humidity,
          status: sensorStatusService.getSensorStatusText('humidity', widget.sensorData['humidity']),
          statusColor: sensorStatusService.getSensorStatusColor('humidity', widget.sensorData['humidity']),
          // 🚫 Humidity detail page disabled temporarily
          // onDoubleTap: () {
          //   TextToSpeech.speak('Opening Humidity details');
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => HumVsTimeGraph(deviceId: widget.deviceId),
          //     ),
          //   );
          // },
        ),
        SizedBox(height: AppDimensions.spacing12),
        SensorReadingCard(
          title: 'Temperature',
          value: _formatValue(widget.sensorData['temperature'], 1),
          unit: '°C',
          icon: FontAwesomeIcons.temperatureFull,
          iconColor: _getTemperatureColor(widget.sensorData['temperature']),
          status: sensorStatusService.getSensorStatusText('temperature', widget.sensorData['temperature']),
          statusColor: sensorStatusService.getSensorStatusColor('temperature', widget.sensorData['temperature']),
          // 🚫 Temperature detail page disabled temporarily
          // onDoubleTap: () {
          //   TextToSpeech.speak('Opening Temperature details');
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => TempVsTimeGraph(deviceId: widget.deviceId),
          //     ),
          //   );
          // },
        ),
        SizedBox(height: AppDimensions.spacing12),
        SensorReadingCard(
          title: 'Water Level',
          value: _formatValue(widget.sensorData['moisture'], 1),
          unit: '%',
          icon: Icons.water_sharp,
          iconColor: AppColors.waterLevel,
          status: sensorStatusService.getSensorStatusText('water', widget.sensorData['moisture']),
          statusColor: sensorStatusService.getSensorStatusColor('water', widget.sensorData['moisture']),
          // 🚫 Water Level detail page disabled temporarily
          // onDoubleTap: () {
          //   TextToSpeech.speak('Opening Water Level details');
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => MoistureVsTimeGraph(deviceId: widget.deviceId),
          //     ),
          //   );
          // },
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
