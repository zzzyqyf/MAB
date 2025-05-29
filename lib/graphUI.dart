import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_final/GraphDataManager.dart';
import 'package:flutter_application_final/deviceMnanger.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_final/TextToSpeech.dart'; // Assuming you're using a package for text-to-speech

class GraphManager extends StatefulWidget {
  final String deviceId;

  const GraphManager({super.key, required this.deviceId});

  @override
  _GraphManagerState createState() => _GraphManagerState();
}

class _GraphManagerState extends State<GraphManager> {
  double minX = 0;
  double maxX = 12;
  late List<FlSpot> spots;
  late Map<String, DateTime> deviceStartTimes;
  late DeviceManager deviceManager;

  @override
  void initState() {
    super.initState();
    deviceStartTimes = {};
    spots = [];
  }

  void announceRange(double minX, double maxX, DateTime cycleStartTime) {
  DateTime startTime = cycleStartTime.add(Duration(minutes: minX.toInt()));
  DateTime endTime = cycleStartTime.add(Duration(minutes: maxX.toInt()));

  String announcement = "You are now exploring data from ${DateFormat('hh:mm a').format(startTime)} to ${DateFormat('hh:mm a').format(endTime)}.";
  TextToSpeech.speak(announcement);
}
    final FlutterTts _tts = FlutterTts();

  void loadHistoricalCycles(DateTime selectedDate, String deviceId) {
    final graphManagerModel = Provider.of<GraphManagerModel>(context, listen: false);
    final cycleBox = graphManagerModel.cycleBox;
  final allCycles = cycleBox.values.toList();

  // Filter cycles for the selected date and device
  final filteredCycles = allCycles.where((cycle) {
    final cycleDate = DateTime.parse(cycle['time']).toLocal();
    return cycle['deviceId'] == deviceId &&
        cycleDate.year == selectedDate.year &&
        cycleDate.month == selectedDate.month &&
        cycleDate.day == selectedDate.day;
  }).toList();

  if (filteredCycles.isEmpty) {
    print("No cycles found for the selected date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}");
    setState(() {
      spots.clear();
            deviceStartTimes[deviceId] = DateTime.fromMillisecondsSinceEpoch(0); // Reset start time

       // Clear graph if no data is found
    });
  } else {
print("Cycles for ${DateFormat('yyyy-MM-dd').format(selectedDate)}:");
    for (var cycle in filteredCycles) {
      print(cycle); // Display filtered cycles in the console
    }
    // Get the start time of the first cycle
    final firstCycleStartTime = DateTime.parse(filteredCycles.first['cycleStartTime']);

    setState(() {
      // Update the device's start time for the x-axis
      deviceStartTimes[deviceId] = firstCycleStartTime;

      // Replace graph data with historical cycle spots
      spots = filteredCycles.map((cycle) {
        final xTime = DateTime.parse(cycle['time']);
        final xElapsed = xTime.difference(firstCycleStartTime).inMinutes.toDouble();
        return FlSpot(xElapsed, cycle['data'].toDouble());
      }).toList();

      spots.sort((a, b) => a.x.compareTo(b.x)); // Ensure sorted order for graph rendering
    });
  }
}



  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {
        final sensorData = deviceManager.sensorData;
        final isActive = deviceManager.isDeviceActive;

        final visibleSpots = spots.where((spot) {
          return spot.x >= minX && spot.x <= maxX;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('${isActive ? "Device Active" : "Device Inactive"} - ${widget.deviceId}'),
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              top: 50.0,
              left: 5.0,
              right: 15.0,
              bottom: 150.0,
            ),
            child: Column(
              children: [
                Expanded(
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
                            reservedSize: 32,
                            interval: 5,
                            getTitlesWidget: (value, titleMeta) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  '${value.toInt()}°C',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      minX: minX,
                      maxX: maxX,
                      minY: 0,
                      maxY: 50,
                      lineBarsData: [
                        LineChartBarData(
                          spots: visibleSpots,
                          isCurved: true,
                          color: Colors.blue,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                          if (event is FlTapUpEvent && response != null && response.lineBarSpots != null) {
                            final touchedSpot = response.lineBarSpots!.first;
                            final DateTime spotTime = deviceStartTimes[widget.deviceId]!
                                .add(Duration(minutes: touchedSpot.x.toInt()));
                            final String message =
                                "${touchedSpot.y.toStringAsFixed(1)}°C at ${DateFormat('hh:mm a').format(spotTime)}.";
                            TextToSpeech.speak(message); // Announce data
                          }
                        },
                        touchTooltipData: const LineTouchTooltipData(tooltipBgColor: Colors.transparent),
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
                            announceRange(minX, maxX, deviceStartTimes[widget.deviceId]!);
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
                            announceRange(minX, maxX, deviceStartTimes[widget.deviceId]!);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1970),
                            lastDate: DateTime.now(),
                          );

                          if (pickedDate != null) {
                            loadHistoricalCycles(pickedDate, widget.deviceId);
                          }
                        },
                        child: const Text("Load Historical Cycles for Date"),
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
