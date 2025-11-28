import 'package:flutter/material.dart';
import 'base_sensor_detail_page.dart';
import '../../domain/entities/sensor_graph_data.dart';

/// Water level detail page with API graph
class WaterLevelDetailPage extends BaseSensorDetailPage {
  const WaterLevelDetailPage({
    Key? key,
    required String deviceId,
    required String mqttId,
  }) : super(
          key: key,
          deviceId: deviceId,
          mqttId: mqttId,
          title: 'Water Level Details',
        );

  @override
  State<WaterLevelDetailPage> createState() => _WaterLevelDetailPageState();
}

class _WaterLevelDetailPageState extends BaseSensorDetailPageState<WaterLevelDetailPage> {
  @override
  String get sensorType => 'Water Level';

  @override
  Color get chartColor => Colors.green;

  @override
  IconData get icon => Icons.water;

  @override
  String get unit => '%';

  @override
  double? get minY => 0;

  @override
  double? get maxY => 100;

  @override
  List<DataPoint> getDataPoints(SensorGraphData graphData) {
    return graphData.waterLevel;
  }
}
