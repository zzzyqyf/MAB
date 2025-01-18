import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_final/DateSelectionPage.dart';
import 'package:flutter_application_final/DeviceIdProvider.dart';
import 'package:flutter_application_final/TextToSpeech.dart';
import 'package:flutter_application_final/deviceMnanger.dart';
import 'package:flutter_application_final/mqttservice.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HumVsTimeGraph extends StatefulWidget {
  final String deviceId; // The deviceId will be passed dynamically

  HumVsTimeGraph({required this.deviceId});

  @override
  _TempVsTimeGraphState createState() => _TempVsTimeGraphState();
}

class _TempVsTimeGraphState extends State<HumVsTimeGraph> {
  double minX = 0;
  double maxX = 6;
  List<FlSpot> hspots = [];
  Map<String, DateTime> hdeviceStartTimes = {};
Map<String, bool> hdeviceStartTimeSet = {};

  late Box hspotBox;
  late Box hcycleBox;
    Map<String, dynamic> sensorData = {}; // Placeholder for sensor data
  late Timer _timer;  // Declare the timer

List<List<FlSpot>> historicalCycles = [];  // New list to store historical cycles
  @override
  void initState() {
    super.initState();
    _initializeHive();
        _startPeriodicCheck(); // Start periodic check

  }

  Future<void> _initializeHive() async {
    hspotBox = await Hive.openBox('humidityData');
    hcycleBox = await Hive.openBox('hcycleData');  // New box for completed cycles
    _loadData();
    // clearSpotBox();
      //printSpotBoxContents(); // Print the contents after loading data
//clearCycleBox();
  }

  /*
void clearSpotBox() async {
  await spotBox.clear(); // Clears all data in the box
  setState(() {
    spots.clear();
    historicalCycles.clear();
    startTime = DateTime.now();
    isStartTimeSet = false;
  });
  print("SpotBox cleared successfully.");
}
void clearCycleBox() async {
  await cycleBox.clear();
  setState(() {
    print("CycleBox cleared successfully.");
  });
}

void printCycleBoxContents() {
  print("CycleBox Contents:");
  for (var key in cycleBox.keys) {
    print("$key: ${cycleBox.get(key)}");
  }
}


*/
void _startPeriodicCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _generateTemperatureData(sensorData); // Check data periodically
    });
  }
  void loadHistoricalCycles(DateTime selectedDate, String deviceId) {
  final allCycles = hcycleBox.values.toList();

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
      hspots.clear();
            hdeviceStartTimes[deviceId] = DateTime.fromMillisecondsSinceEpoch(0); // Reset start time

       // Clear graph if no data is found
    });
  } else {
print("Cycles for ${DateFormat('yyyy-MM-dd').format(selectedDate)}:");
    for (var cycle in filteredCycles) {
      print(cycle); // Display filtered cycles in the console
    }
    // Get the start time of the first cycle
    final hfirstCycleStartTime = DateTime.parse(filteredCycles.first['cycleStartTime']);

    setState(() {
      // Update the device's start time for the x-axis
      hdeviceStartTimes[deviceId] = hfirstCycleStartTime;

      // Replace graph data with historical cycle spots
      hspots = filteredCycles.map((cycle) {
        final xTime = DateTime.parse(cycle['time']);
        final xElapsed = xTime.difference(hfirstCycleStartTime).inMinutes.toDouble();
        return FlSpot(xElapsed, cycle['hdata'].toDouble());
      }).toList();

      hspots.sort((a, b) => a.x.compareTo(b.x)); // Ensure sorted order for graph rendering
    });
  }
}



  void _loadData() {
  // Retrieve stored data for the specific device
  final storedData = hspotBox.get('${widget.deviceId}_spots', defaultValue: []);
  final storedStartTime = hspotBox.get('${widget.deviceId}_startTime', defaultValue: DateTime.now().toIso8601String());

  setState(() {
    // Load the spots and startTime specific to the current device
    hspots = (storedData as List<dynamic>)
        .map((item) => FlSpot(item['x'], item['y']))
        .toList();
    hdeviceStartTimes[widget.deviceId] = DateTime.parse(storedStartTime);
    hdeviceStartTimeSet[widget.deviceId] = true; // Mark startTime as set
  });
}

void _saveData() {
  // Prepare the data specific to the current device
  final dataToSave = hspots.map((spot) => {'x': spot.x, 'y': spot.y}).toList();
  final deviceStartTime = hdeviceStartTimes[widget.deviceId];

  // Save data and startTime for the current device
  hspotBox.put('${widget.deviceId}_spots', dataToSave);
  if (deviceStartTime != null) {
    hspotBox.put('${widget.deviceId}_startTime', deviceStartTime.toIso8601String());
  }
}


  @override
  void dispose() {
      _saveData(); // Save data when leaving the page
    hspotBox.close();
    super.dispose();
  }

  String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
//isDataReceived and periodic check
void testingConnection(){
//mqttService.isDataReceived();
        //_generateTemperatureData();

}

  void _generateTemperatureData(Map<String, dynamic> sensorData) {
  DateTime currentTime = DateTime.now();

  // Use device manager to check device status
  final deviceManager = Provider.of<DeviceManager>(context, listen: false);
  if (sensorData.isEmpty || !deviceManager.deviceIsActive(widget.deviceId)) {
    return;
  }

  // Initialize device-specific state maps if not already present
  hdeviceStartTimes.putIfAbsent(widget.deviceId, () => currentTime);
  hdeviceStartTimeSet.putIfAbsent(widget.deviceId, () => false);

  // Set the start time for this device if not already set
  if (!hdeviceStartTimeSet[widget.deviceId]!) {
    hdeviceStartTimes[widget.deviceId] = currentTime;
    hdeviceStartTimeSet[widget.deviceId] = true;
  }

  // Use the device-specific start time
  DateTime deviceStartTime = hdeviceStartTimes[widget.deviceId]!;

  sensorData.entries
      .where((entry) => entry.key.contains('humidity'))
      .forEach((entry) {
    final humidity = double.tryParse(entry.value.toString()) ?? 0.0;
    final timeElapsed = currentTime.difference(deviceStartTime).inMinutes.toDouble();
    final spot = FlSpot(timeElapsed, humidity);

    hspots.add(spot);
  });

  hspots.sort((a, b) => a.x.compareTo(b.x));

  // Handle cycle completion for this device
  if (hspots.isNotEmpty && hspots.last.x > 3) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        setState(() {
          final cycleId = DateTime.now().millisecondsSinceEpoch.toString();

          // Generate cycle entries specific to this device
          final List<Map<String, dynamic>> cycleEntries = hspots.map((spot) {
            final timestamp = deviceStartTime.add(Duration(
                minutes: spot.x.toInt(),
                seconds: ((spot.x - spot.x.toInt()) * 60).toInt()));
            return {
              'id': cycleId,
              'time': timestamp.toIso8601String(),
              'hdata': spot.y,
              'cycleStartTime': deviceStartTime.toIso8601String(),
              'deviceId': widget.deviceId,
            };
          }).toList();

          // Add cycle entries to persistent storage
          for (var entry in cycleEntries) {
            hcycleBox.add(entry);
          }

          // Reset state for the next cycle
          hdeviceStartTimes[widget.deviceId] = DateTime.now();
          hdeviceStartTimeSet[widget.deviceId] = false;
          hspots.clear();
        });

        _saveData(); // Save the cleared state of current data
      });
    }
  }
}
void announceRange(double minX, double maxX, DateTime cycleStartTime) {
  DateTime startTime = cycleStartTime.add(Duration(minutes: minX.toInt()));
  DateTime endTime = cycleStartTime.add(Duration(minutes: maxX.toInt()));

  String announcement = "You are now exploring data from " +
      DateFormat('hh:mm a').format(startTime) +
      " to " +
      DateFormat('hh:mm a').format(endTime) +
      ".";
  TextToSpeech.speak(announcement);
}
    FlutterTts _tts = FlutterTts();


  @override
Widget build(BuildContext context) {
  return Consumer<DeviceManager>(
    builder: (context, deviceManager, child) {
      final sensorData = deviceManager.sensorData;
      _generateTemperatureData(sensorData);
      final isActive = deviceManager.isDeviceActive;

      final visibleSpots = hspots.where((spot) {
        return spot.x >= minX && spot.x <= maxX;
      }).toList();

      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${isActive ? "Device Active" : "Device Inactive"} - ${widget.deviceId}',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color.fromARGB(255, 200, 204, 206),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 6, 94, 135),
                Color.fromARGB(255, 84, 90, 95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: LineChart(
                    LineChartData(
                      backgroundColor: Colors.transparent,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 10,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.3),
                            strokeWidth: 0.8,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 1,
                            getTitlesWidget: (value, titleMeta) {
                              DateTime cycleStartTime =
                                  hdeviceStartTimes[widget.deviceId] ?? DateTime.now();
                              DateTime xTime = cycleStartTime.add(Duration(minutes: value.toInt()));

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('HH:mm').format(xTime),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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
                                  '${value.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      minX: minX,
                      maxX: maxX,
                      minY: 0,
                      maxY: 90,
                      lineBarsData: [
                        LineChartBarData(
                          spots: visibleSpots,
                          isCurved: true,
                          color: Colors.white,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.5),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                          if (event is FlTapUpEvent &&
                              response != null &&
                              response.lineBarSpots != null) {
                            final touchedSpot = response.lineBarSpots!.first;
                            final DateTime spotTime = hdeviceStartTimes[widget.deviceId]!
                                .add(Duration(minutes: touchedSpot.x.toInt()));
                            final String message =
                                "${touchedSpot.y.toStringAsFixed(1)}% at ${DateFormat('hh:mm a').format(spotTime)}.";
                            TextToSpeech.speak(message);
                          }
                        },
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.white.withOpacity(0.8),
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final DateTime spotTime = hdeviceStartTimes[widget.deviceId]!
                                  .add(Duration(minutes: spot.x.toInt()));
                              return LineTooltipItem(
                                '${spot.y.toStringAsFixed(1)}% at ${DateFormat('hh:mm a').format(spotTime)}',
                                TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
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
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            if (minX > 0) {
                              minX -= 1;
                              maxX -= 1;
                            }
                            announceRange(minX, maxX, hdeviceStartTimes[widget.deviceId]!);
                          });
                        },
                      ),
                      Text(
                        'Scroll Time Range: $minX - $maxX minutes',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            if (maxX < 24) {
                              minX += 1;
                              maxX += 1;
                            }
                            announceRange(minX, maxX, hdeviceStartTimes[widget.deviceId]!);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DateSelectionPage(
                          onDateSelected: (selectedDate) {
                            loadHistoricalCycles(selectedDate, widget.deviceId);
                            TextToSpeech.speak(
                              "Selected date: ${selectedDate.month}-${selectedDate.day}-${selectedDate.year}",
                            );
                          },
                        ),
                      ),
                    );
                  },
                  child: Text("Load Historical Cycles for Date"),
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

void main() async {
  await Hive.initFlutter();
  runApp(
    ChangeNotifierProvider(
      create: (_) => DeviceManager(),
      child: MaterialApp(
        home: HumVsTimeGraph(deviceId: ''), // Pass the deviceId dynamically
      ),
    ),
  );
}
