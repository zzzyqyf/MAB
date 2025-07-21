import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../viewmodels/deviceManager.dart';

class MoistureVsTimeGraph extends StatefulWidget {
  final String deviceId;

  const MoistureVsTimeGraph({super.key, required this.deviceId});
  
  @override
  State<MoistureVsTimeGraph> createState() => _MoistureVsTimeGraphState();
}

class _MoistureVsTimeGraphState extends State<MoistureVsTimeGraph> {
  double minX = 0;
  double maxX = 3;
  List<FlSpot> spots = [];
  Map<String, DateTime> deviceStartTimes = {};
  Map<String, bool> deviceStartTimeSet = {};
  late Box spotBox;
  late Box cycleBox;
  Map<String, dynamic> sensorData = {};
  late Timer _timer;
  List<List<FlSpot>> historicalCycles = [];

  @override
  void initState() {
    super.initState();
    _initializeHive();
    _startPeriodicCheck();
  }

  Future<void> _initializeHive() async {
    spotBox = await Hive.openBox('moistureData');
    cycleBox = await Hive.openBox('moistureCycleData');
    _loadData();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final deviceManager = Provider.of<DeviceManager>(context, listen: false);
      final sensorData = deviceManager.sensorData;
      if (sensorData.isNotEmpty && mounted) {
        _generateMoistureData(sensorData);
      }
    });
  }

  void _loadData() {
    final dataList = spotBox.get('${widget.deviceId}_spots', defaultValue: []);
    if (dataList != null) {
      spots = dataList.map<FlSpot>((data) => FlSpot(data['x'].toDouble(), data['y'].toDouble())).toList();
    }
    
    final startTimeString = spotBox.get('${widget.deviceId}_startTime');
    if (startTimeString != null) {
      deviceStartTimes[widget.deviceId] = DateTime.parse(startTimeString);
      deviceStartTimeSet[widget.deviceId] = true;
    }
    
    _loadHistoricalCycles();
    
    if (spots.isNotEmpty) {
      maxX = spots.last.x;
      minX = maxX > 2 ? maxX - 2 : 0;
    }
  }

  void _loadHistoricalCycles() {
    final cycleKeys = cycleBox.keys.where((key) => key.toString().contains('${widget.deviceId}_cycle_')).toList();
    
    for (var key in cycleKeys) {
      final cycleData = cycleBox.get(key, defaultValue: []);
      if (cycleData != null) {
        List<FlSpot> cycleSpots = cycleData.map<FlSpot>((data) => FlSpot(data['x'].toDouble(), data['y'].toDouble())).toList();
        historicalCycles.add(cycleSpots);
      }
    }
  }

  void _saveData() {
    final dataToSave = spots.map((spot) => {'x': spot.x, 'y': spot.y}).toList();
    final deviceStartTime = deviceStartTimes[widget.deviceId];

    spotBox.put('${widget.deviceId}_spots', dataToSave);
    if (deviceStartTime != null) {
      spotBox.put('${widget.deviceId}_startTime', deviceStartTime.toIso8601String());
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _saveData();
    spotBox.close();
    super.dispose();
  }

  String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  void _generateMoistureData(Map<String, dynamic> sensorData) {
    DateTime currentTime = DateTime.now();

    final deviceManager = Provider.of<DeviceManager>(context, listen: false);
    if (sensorData.isEmpty || !deviceManager.deviceIsActive(widget.deviceId)) {
      return;
    }

    deviceStartTimes.putIfAbsent(widget.deviceId, () => currentTime);
    deviceStartTimeSet.putIfAbsent(widget.deviceId, () => false);

    if (!deviceStartTimeSet[widget.deviceId]!) {
      deviceStartTimes[widget.deviceId] = currentTime;
      deviceStartTimeSet[widget.deviceId] = true;
    }

    DateTime deviceStartTime = deviceStartTimes[widget.deviceId]!;

    sensorData.entries
        .where((entry) => entry.key.contains('moisture'))
        .forEach((entry) {
      final moisture = double.tryParse(entry.value.toString()) ?? 0.0;
      final double elapsedMinutes = currentTime.difference(deviceStartTime).inMinutes.toDouble();

      setState(() {
        if (spots.isEmpty || spots.last.x < elapsedMinutes) {
          spots.add(FlSpot(elapsedMinutes, moisture));
          maxX = elapsedMinutes;
          minX = maxX > 2 ? maxX - 2 : 0;
        }
      });
    });

    if (spots.isNotEmpty && spots.last.x > 2) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          setState(() {
            final cycleId = DateTime.now().millisecondsSinceEpoch.toString();

            cycleBox.put('${widget.deviceId}_cycle_$cycleId', spots.map((spot) => {'x': spot.x, 'y': spot.y}).toList());

            historicalCycles.add(List.from(spots));
            spots.clear();
            minX = 0;
            maxX = 3;
            deviceStartTimes[widget.deviceId] = currentTime;
          });
          _saveData();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {
        final sensorData = deviceManager.sensorData;
        final isActive = deviceManager.isDeviceActive;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Moisture vs Time'),
            backgroundColor: Colors.green.withOpacity(0.1),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  final currentMoisture = sensorData['moisture'] ?? 'No data';
                  TextToSpeech.speak('Current moisture level is $currentMoisture percent');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Moisture Reading
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.water_drop, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Moisture',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${sensorData['moisture']?.toStringAsFixed(1) ?? '--'}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Graph
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: LineChart(
                      LineChartData(
                        minX: minX,
                        maxX: maxX,
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          if (spots.isNotEmpty)
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [Colors.green, Colors.green.withOpacity(0.3)],
                                stops: const [0.1, 1.0],
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.3),
                                    Colors.green.withOpacity(0.1),
                                  ],
                                  stops: const [0.1, 1.0],
                                ),
                              ),
                            ),
                          ...historicalCycles.map((cycle) => LineChartBarData(
                            spots: cycle,
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [Colors.grey.withOpacity(0.6), Colors.grey.withOpacity(0.3)],
                              stops: const [0.1, 1.0],
                            ),
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                          )),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}%',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (deviceStartTimes[widget.deviceId] != null) {
                                  final time = deviceStartTimes[widget.deviceId]!.add(Duration(minutes: value.toInt()));
                                  return Text(
                                    formatTime(time),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return Text('${value.toInt()}m');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 20,
                          verticalInterval: 0.5,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.3),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                        ),
                        lineTouchData: LineTouchData(
                          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                            if (event is FlTapUpEvent && response != null && response.lineBarSpots != null) {
                              final touchedSpot = response.lineBarSpots!.first;
                              final DateTime spotTime = (deviceStartTimes[widget.deviceId] ?? DateTime.now())
                                  .add(Duration(minutes: touchedSpot.x.toInt()));
                              final String message =
                                  "${touchedSpot.y.toStringAsFixed(1)}% moisture at ${DateFormat('hh:mm a').format(spotTime)}.";
                              TextToSpeech.speak(message);
                            }
                          },
                          touchTooltipData: const LineTouchTooltipData(tooltipPadding: EdgeInsets.zero),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
