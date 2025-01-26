import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class TempVsTimeGraph extends StatefulWidget {
  final String deviceId;

  TempVsTimeGraph({required this.deviceId});

  @override
  _TempVsTimeGraphState createState() => _TempVsTimeGraphState();
}

class _TempVsTimeGraphState extends State<TempVsTimeGraph> with WidgetsBindingObserver {
  double minX = 0;
  double maxX = 3;
  List<FlSpot> spots = [];
  late Box spotBox;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeHive();
    _startBackgroundTimer();
  }

  Future<void> _initializeHive() async {
    spotBox = await Hive.openBox('temperatureData');
    _loadData();
  }

  void _loadData() {
    final storedData = spotBox.get('${widget.deviceId}_spots', defaultValue: []);
    setState(() {
      spots = (storedData as List<dynamic>)
          .map((item) => FlSpot(item['x'], item['y']))
          .toList();
    });
  }

  void _saveData() {
    final dataToSave = spots.map((spot) => {'x': spot.x, 'y': spot.y}).toList();
    spotBox.put('${widget.deviceId}_spots', dataToSave);
  }

  void _startBackgroundTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      // Simulate periodic data updates
      _generateTemperatureData();
    });
  }

  void _generateTemperatureData() {
    final currentTime = DateTime.now();
    final elapsedTime = currentTime.second.toDouble();
    final temperature = (20 + (elapsedTime % 10)); // Mock data
    setState(() {
      spots.add(FlSpot(elapsedTime, temperature));
      if (spots.length > 20) spots.removeAt(0);
    });
    _saveData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    _saveData();
    spotBox.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Save data when app goes to the background
      _saveData();
    } else if (state == AppLifecycleState.resumed) {
      // Resume the timer when the app becomes active
      _startBackgroundTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Temp vs Time Graph')),
      body: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, titleMeta) {
                  return Text(value.toStringAsFixed(1));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, titleMeta) {
                  return Text('${value.toInt()}°C');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          minX: minX,
          maxX: maxX,
          minY: 0,
          maxY: 50,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  await Hive.initFlutter();
  runApp(
    MaterialApp(
      home: TempVsTimeGraph(deviceId: 'device1'),
    ),
  );
}
