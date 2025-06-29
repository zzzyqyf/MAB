import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../viewmodels/deviceManager.dart';

class TemperatureGraph extends StatefulWidget {
  final String deviceId;

  const TemperatureGraph({super.key, required this.deviceId});

  @override
  _TemperatureGraphState createState() => _TemperatureGraphState();
}

class _TemperatureGraphState extends State<TemperatureGraph> {
  double minX = 0;
  double maxX = 3;
  List<FlSpot> spots = [];

  @override
  void initState() {
    super.initState();
    // Initialize with empty spots
    spots = [];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {
        final sensorData = deviceManager.sensorData;
        final isActive = deviceManager.isDeviceActive;

        // Filter for temperature data and create spots
        final visibleSpots = spots.where((spot) {
          return spot.x >= minX && spot.x <= maxX;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('${isActive ? "Device Active" : "Device Inactive"} - ${widget.deviceId}'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              top: 12.0,
              left: 8.0,
              right: 8.0,
              bottom: 8.0,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.only(
                      right: 24,
                      bottom: 24,
                      left: 0,
                      top: 0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 1,
                              getTitlesWidget: (value, titleMeta) {
                                DateTime cycleStartTime = deviceManager.deviceStartTimes[widget.deviceId] ?? DateTime.now();
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
                                    '${value.toInt()}°C',
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
                        ),
                        borderData: FlBorderData(show: true),
                        minX: minX,
                        maxX: maxX,
                        minY: 0,
                        maxY: 40,
                        lineBarsData: [
                          LineChartBarData(
                            spots: visibleSpots,
                            isCurved: true,
                            color: Colors.red,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                            if (event is FlTapUpEvent && response != null && response.lineBarSpots != null) {
                              final touchedSpot = response.lineBarSpots!.first;
                              final DateTime spotTime = (deviceManager.deviceStartTimes[widget.deviceId] ?? DateTime.now())
                                  .add(Duration(minutes: touchedSpot.x.toInt()));
                              final String message =
                                  "${touchedSpot.y.toStringAsFixed(1)}°C at ${DateFormat('hh:mm a').format(spotTime)}.";
                              TextToSpeech.speak(message);
                            }
                          },
                          touchTooltipData: const LineTouchTooltipData(tooltipPadding: EdgeInsets.zero),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            if (minX > 0) {
                              minX -= 1;
                              maxX -= 1;
                            }
                          });
                        },
                      ),
                      Text('Scroll Time Range: $minX - $maxX minutes'),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          setState(() {
                            if (maxX < 12) {
                              minX += 1;
                              maxX += 1;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Scroll left action
                        },
                        child: const Text('Scroll Left'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Scroll right action
                        },
                        child: const Text('Scroll Right'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
