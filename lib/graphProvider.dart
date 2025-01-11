import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'deviceMnanger.dart';

class GraphProvider extends ChangeNotifier {
  final DeviceManager deviceManager; // Reference to the DeviceManager
  double minX = 0;
  double maxX = 6; // 6-minute period
  List<FlSpot> spots = [];
  DateTime startTime = DateTime.now(); // Track the start time for real-time plotting
  bool isStartTimeSet = false; // Flag to indicate if the start time is set

  GraphProvider({required this.deviceManager}) {
    // Add a listener to the DeviceManager to fetch new data
    deviceManager.addListener(_onDeviceManagerUpdate);
  }

  // Callback when DeviceManager updates
  void _onDeviceManagerUpdate() {
    updateGraphData(deviceManager.sensorData);
  }

  // Update graph data based on new sensor data
  void updateGraphData(Map<String, dynamic> sensorData) {
  DateTime currentTime = DateTime.now();
  if (!isStartTimeSet) {
    startTime = currentTime;
    isStartTimeSet = true;
  }
  sensorData.entries
      .where((entry) => entry.key.contains('temperature'))
      .forEach((entry) {
    final temperature = double.tryParse(entry.value.toString()) ?? 0.0;
    final timeElapsed = currentTime.difference(startTime).inMinutes.toDouble();
    final spot = FlSpot(timeElapsed, temperature);

    print("Adding data point: $spot"); // Add print to debug
    spots.add(spot);
  });
  spots.sort((a, b) => a.x.compareTo(b.x));
  if (spots.isNotEmpty && spots.last.x > 24) {
    spots.clear();
    startTime = DateTime.now();
    isStartTimeSet = false;
  }
  notifyListeners();
}

  void scrollLeft() {
    if (minX > 0) {
      minX -= 1;
      maxX -= 1;
      notifyListeners();
    }
  }

  void scrollRight() {
    if (maxX < 24) {
      minX += 1;
      maxX += 1;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    deviceManager.removeListener(_onDeviceManagerUpdate);
    super.dispose();
  }
}
