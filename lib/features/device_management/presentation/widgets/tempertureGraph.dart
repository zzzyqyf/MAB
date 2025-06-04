import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Project imports
import '../viewmodels/deviceMnanger.dart';

class TemperatureGraph extends StatelessWidget {
  final String deviceId;

  const TemperatureGraph({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final deviceManager = Provider.of<DeviceManager>(context);
    final temperatureHistory = deviceManager.sensorData[deviceId]?['temperatureHistory'] ?? [];

    List<FlSpot> spots = temperatureHistory.map<FlSpot>((entry) {
      final timestamp = entry['timestamp'] as DateTime;
      final temperature = entry['temperature'] as double;

      // Convert timestamp to seconds since start for graph
      final seconds = timestamp.difference(temperatureHistory.first['timestamp']).inSeconds.toDouble();
      return FlSpot(seconds, temperature);
    }).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: const FlTitlesData(show: true),
            borderData: FlBorderData(
              border: const Border(
                left: BorderSide(color: Colors.black),
                bottom: BorderSide(color: Colors.black),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(show: false),
                spots: spots,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
