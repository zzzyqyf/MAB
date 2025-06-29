import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/TextToSpeech.dart';

/// Abstract base class for graph components
/// Implements common graph functionality and enforces OOP principles
abstract class BaseGraph extends StatefulWidget {
  final String deviceId;

  const BaseGraph({super.key, required this.deviceId});
}

/// Base state class that provides common graph functionality
abstract class BaseGraphState<T extends BaseGraph> extends State<T> {
  double minX = 0;
  double maxX = 3;
  List<FlSpot> spots = [];
  Map<String, DateTime> deviceStartTimes = {};
  Map<String, bool> deviceStartTimeSet = {};
  
  // Abstract methods that must be implemented by subclasses
  String get dataKey; // e.g., 'humidity', 'lightState', 'temperature'
  String get unit; // e.g., '%', '°C'
  String get boxName; // e.g., 'humidityData', 'lightData'
  String get cycleBoxName; // e.g., 'humidityMCycleData', 'lightCycleData'
  
  // Common chart configuration
  FlTitlesData get titlesData {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          interval: 1,
          getTitlesWidget: (value, titleMeta) {
            DateTime cycleStartTime = deviceStartTimes[widget.deviceId] ?? DateTime.now();
            DateTime xTime = cycleStartTime.add(Duration(minutes: value.toInt()));
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                DateFormat('HH:mm').format(xTime),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          interval: 5,
          getTitlesWidget: (value, titleMeta) {
            return Container(
              alignment: Alignment.centerRight,
              width: 40,
              child: Text(
                '${value.toInt()}$unit',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  // Common line chart bar data configuration
  List<LineChartBarData> get lineChartBarData {
    final visibleSpots = spots.where((spot) {
      return spot.x >= minX && spot.x <= maxX;
    }).toList();

    return [
      LineChartBarData(
        spots: visibleSpots,
        isCurved: true,
        color: Colors.blue,
        belowBarData: BarAreaData(
          show: true,
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
    ];
  }

  // Common touch callback for data point interaction
  void onTouchCallback(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlTapUpEvent && response != null && response.lineBarSpots != null) {
      final touchedSpot = response.lineBarSpots!.first;
      final DateTime spotTime = deviceStartTimes[widget.deviceId]!
          .add(Duration(minutes: touchedSpot.x.toInt()));
      final String message =
          "${touchedSpot.y.toStringAsFixed(1)}$unit at ${DateFormat('hh:mm a').format(spotTime)}.";
      TextToSpeech.speak(message);
    }
  }

  // Navigation methods
  void navigatePrevious() {
    setState(() {
      if (minX > 0) {
        minX -= 1;
        maxX -= 1;
      }
    });
  }

  void navigateNext() {
    setState(() {
      if (maxX < 12) {
        minX += 1;
        maxX += 1;
      }
    });
  }

  // Common method to handle historical data loading
  void loadHistoricalCycles(DateTime selectedDate, String deviceId) {
    // This would be implemented in each specific graph with their cycle box
  }
}
