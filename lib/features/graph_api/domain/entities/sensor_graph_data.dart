/// Domain entity for sensor graph data
class SensorGraphData {
  final List<DataPoint> humidity;
  final List<DataPoint> temperature;
  final List<DataPoint> waterLevel;

  SensorGraphData({
    required this.humidity,
    required this.temperature,
    required this.waterLevel,
  });

  bool get hasData => humidity.isNotEmpty || temperature.isNotEmpty || waterLevel.isNotEmpty;
}

class DataPoint {
  final double value;
  final DateTime time;

  DataPoint({
    required this.value,
    required this.time,
  });
}
