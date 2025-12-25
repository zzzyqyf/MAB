/// Graph data model from API response
import 'package:flutter/foundation.dart';

class GraphDataModel {
  final List<SensorDataPointModel> humidity;
  final List<SensorDataPointModel> temperature;
  final List<SensorDataPointModel> waterLevel;

  GraphDataModel({
    required this.humidity,
    required this.temperature,
    required this.waterLevel,
  });

  factory GraphDataModel.fromJson(Map<String, dynamic> json) {
    // API returns data in format:
    // {"factoryId": 6, "controllerId": "94B97EC04AD4", "total": 159, 
    //  "items": [{"_id": "...", "bucket_start": {...}, "data": [81, 30, 1], "ts": {...}}]}
    // where data array is [humidity, temperature, waterLevel]
    
    final itemsList = json['items'] as List? ?? [];
    
    final humidityPoints = <SensorDataPointModel>[];
    final temperaturePoints = <SensorDataPointModel>[];
    final waterLevelPoints = <SensorDataPointModel>[];
    
    debugPrint('📊 Parsing ${itemsList.length} items from API');
    
    // Extract each sensor value from the items array
    for (var item in itemsList) {
      if (item is! Map<String, dynamic>) continue;
      
      // Get timestamp from ts field (MongoDB $numberLong format)
      final tsData = item['ts'];
      int timestampMs = 0;
      if (tsData is Map && tsData.containsKey('\$numberLong')) {
        timestampMs = int.tryParse(tsData['\$numberLong'].toString()) ?? 0;
      } else if (tsData is int) {
        timestampMs = tsData;
      }
      
      final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
      final timeStr = timestamp.toIso8601String();
      
      // Get sensor data array: [humidity, temperature, waterLevel]
      final dataArray = item['data'] as List?;
      if (dataArray != null && dataArray.length >= 3) {
        final humidity = (dataArray[0] ?? 0).toDouble();
        final temperature = (dataArray[1] ?? 0).toDouble();
        final waterLevel = (dataArray[2] ?? 0).toDouble();
        
        // Log first data point for verification
        if (humidityPoints.isEmpty) {
          final localTime = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
          debugPrint('📊 First data point: H=$humidity%, T=$temperature°C, W=$waterLevel');
          debugPrint('📊 Time: UTC=${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}, Local=${localTime.hour}:${localTime.minute.toString().padLeft(2, '0')}');
        }
        
        // Index 0: Humidity
        humidityPoints.add(SensorDataPointModel(
          value: humidity,
          time: timeStr,
        ));
        
        // Index 1: Temperature
        temperaturePoints.add(SensorDataPointModel(
          value: temperature,
          time: timeStr,
        ));
        
        // Index 2: Water Level (moisture)
        waterLevelPoints.add(SensorDataPointModel(
          value: waterLevel,
          time: timeStr,
        ));
      }
    }
    
    debugPrint('📊 Parsed: ${humidityPoints.length} humidity, ${temperaturePoints.length} temp, ${waterLevelPoints.length} water points');
    
    return GraphDataModel(
      humidity: humidityPoints,
      temperature: temperaturePoints,
      waterLevel: waterLevelPoints,
    );
  }
}

class SensorDataPointModel {
  final double value;
  final String time;

  SensorDataPointModel({
    required this.value,
    required this.time,
  });

  factory SensorDataPointModel.fromJson(Map<String, dynamic> json) {
    return SensorDataPointModel(
      value: (json['value'] ?? 0).toDouble(),
      time: json['time']?.toString() ?? '',
    );
  }

  DateTime get dateTime {
    try {
      // API returns timestamps already in local timezone
      return DateTime.parse(time);
    } catch (e) {
      return DateTime.now();
    }
  }
}
