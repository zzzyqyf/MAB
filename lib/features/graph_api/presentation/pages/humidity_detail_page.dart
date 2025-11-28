import 'package:flutter/material.dart';
import 'base_sensor_detail_page.dart';
import '../../domain/entities/sensor_graph_data.dart';

/// Humidity detail page with API graph
class HumidityDetailPage extends BaseSensorDetailPage {
  const HumidityDetailPage({
    Key? key,
    required String deviceId,
    required String mqttId,
  }) : super(
          key: key,
          deviceId: deviceId,
          mqttId: mqttId,
          title: 'Humidity Details',
        );

  @override
  State<HumidityDetailPage> createState() => _HumidityDetailPageState();
}

class _HumidityDetailPageState extends BaseSensorDetailPageState<HumidityDetailPage> {
  @override
  String get sensorType => 'Humidity';

  @override
  Color get chartColor => Colors.blue;

  @override
  IconData get icon => Icons.water_drop;

  @override
  String get unit => '%';

  @override
  double? get minY => 0;

  @override
  double? get maxY => 100;

  @override
  List<DataPoint> getDataPoints(SensorGraphData graphData) {
    return graphData.humidity;
  }
}
