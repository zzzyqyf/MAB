import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class GraphManagerModel extends ChangeNotifier {
  final String deviceId;
  late Box spotBox;
  late Box cycleBox;
  List<FlSpot> spots = [];
  Map<String, DateTime> deviceStartTimes = {};
  Map<String, bool> deviceStartTimeSet = {};
  late Timer _timer;

  GraphManagerModel(this.deviceId);

  Future<void> initialize() async {
    spotBox = await Hive.openBox('temperatureData');
    cycleBox = await Hive.openBox('cycleData');
    _loadData();
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _generateTemperatureData(); // Generate data periodically
    });
  }

  void _loadData() {
    final storedData = spotBox.get('${deviceId}_spots', defaultValue: []);
    final storedStartTime = spotBox.get('${deviceId}_startTime', defaultValue: DateTime.now().toIso8601String());

    spots = (storedData as List<dynamic>)
        .map((item) => FlSpot(item['x'], item['y']))
        .toList();
    deviceStartTimes[deviceId] = DateTime.parse(storedStartTime);
    deviceStartTimeSet[deviceId] = true;
    notifyListeners(); // Notify listeners when data is loaded
  }

  void _saveData() {
    final dataToSave = spots.map((spot) => {'x': spot.x, 'y': spot.y}).toList();
    final deviceStartTime = deviceStartTimes[deviceId];

    spotBox.put('${deviceId}_spots', dataToSave);
    if (deviceStartTime != null) {
      spotBox.put('${deviceId}_startTime', deviceStartTime.toIso8601String());
    }
  }

  void _generateTemperatureData() {
    DateTime currentTime = DateTime.now();
    // Simulate temperature data (Replace with actual sensor data)
    double temperature = 25.0 + (currentTime.second % 5); // Example

    final timeElapsed = currentTime.difference(deviceStartTimes[deviceId]!).inMinutes.toDouble();
    final spot = FlSpot(timeElapsed, temperature);
    spots.add(spot);

    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.isNotEmpty && spots.last.x > 12) {
      _handleCycleCompletion();
    }

    notifyListeners(); // Notify listeners when new data is generated
  }

  void _handleCycleCompletion() {
    // Store completed cycle data
    final cycleId = DateTime.now().millisecondsSinceEpoch.toString();
    final cycleEntries = spots.map((spot) {
      final timestamp = deviceStartTimes[deviceId]!.add(Duration(minutes: spot.x.toInt()));
      return {
        'id': cycleId,
        'time': timestamp.toIso8601String(),
        'data': spot.y,
        'cycleStartTime': deviceStartTimes[deviceId]?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'deviceId': deviceId,
      };
    }).toList();

    for (var entry in cycleEntries) {
      cycleBox.add(entry);
    }

    deviceStartTimes[deviceId] = DateTime.now();
    deviceStartTimeSet[deviceId] = false;
    spots.clear();
    _saveData();
  }
}
