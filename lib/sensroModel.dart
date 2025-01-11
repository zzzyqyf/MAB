import 'package:hive/hive.dart';

//part 'sensor_data.g.dart';  // This is needed for code generation.

@HiveType(typeId: 1)
class SensorData {
  @HiveField(0)
  final double temperature;

  @HiveField(1)
  final double humidity;

  @HiveField(2)
  final int lightState;

  @HiveField(3)
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.lightState,
    required this.timestamp,
  });
}
