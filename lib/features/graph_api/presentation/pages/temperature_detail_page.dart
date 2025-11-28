import 'package:flutter/material.dart';
import 'base_sensor_detail_page.dart';
import '../../domain/entities/sensor_graph_data.dart';

/// Temperature detail page with API graph
class TemperatureDetailPage extends BaseSensorDetailPage {
  const TemperatureDetailPage({
    Key? key,
    required String deviceId,
    required String mqttId,
  }) : super(
          key: key,
          deviceId: deviceId,
          mqttId: mqttId,
          title: 'Temperature Details',
        );

  @override
  State<TemperatureDetailPage> createState() => _TemperatureDetailPageState();
}

class _TemperatureDetailPageState extends BaseSensorDetailPageState<TemperatureDetailPage> {
  @override
  String get sensorType => 'Temperature';

  @override
  Color get chartColor => Colors.red;

  @override
  IconData get icon => Icons.thermostat;

  @override
  String get unit => '°C';

  @override
  double? get minY => 0;

  @override
  double? get maxY => 50;

  @override
  List<DataPoint> getDataPoints(SensorGraphData graphData) {
    return graphData.temperature;
  }
}
