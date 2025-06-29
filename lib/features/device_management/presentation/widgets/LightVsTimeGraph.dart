import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Project imports
import '../../../../shared/services/TextToSpeech.dart';
import '../../../../shared/widgets/graph_components/graph_components.dart';
import '../viewmodels/deviceManager.dart';

class LightVsTimeGraph extends StatefulWidget {
  final String deviceId; // The deviceId will be passed dynamically

  const LightVsTimeGraph({super.key, required this.deviceId});
  @override
  State<LightVsTimeGraph> createState() => _LightVsTimeGraphState();
}

class _LightVsTimeGraphState extends State<LightVsTimeGraph> {
  double minX = 0;
  double maxX = 3;
  List<FlSpot> spots = [];
  Map<String, DateTime> deviceStartTimes = {};
Map<String, bool> deviceStartTimeSet = {};
  late Box spotBox;
  late Box cycleBox;
    Map<String, dynamic> sensorData = {}; // Placeholder for sensor data
  late Timer _timer;  // Declare the timer

List<List<FlSpot>> historicalCycles = [];  // New list to store historical cycles
  @override
  void initState() {
    super.initState();
    _initializeHive();
        _startPeriodicCheck(); // Start periodic check

  }  Future<void> _initializeHive() async {
    spotBox = await Hive.openBox('lightData');
    cycleBox = await Hive.openBox('lightCycleData');  // New box for completed cycles
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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _generateLightData(sensorData); // Check data periodically
    });
  }
  void loadHistoricalCycles(DateTime selectedDate, String deviceId) {
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



  void _loadData() {
  // Retrieve stored data for the specific device
  final storedData = spotBox.get('${widget.deviceId}_spots', defaultValue: []);
  final storedStartTime = spotBox.get('${widget.deviceId}_startTime', defaultValue: DateTime.now().toIso8601String());

  setState(() {
    // Load the spots and startTime specific to the current device
    spots = (storedData as List<dynamic>)
        .map((item) => FlSpot(item['x'], item['y']))
        .toList();
    deviceStartTimes[widget.deviceId] = DateTime.parse(storedStartTime);
    deviceStartTimeSet[widget.deviceId] = true; // Mark startTime as set
  });
}

void _saveData() {
  // Prepare the data specific to the current device
  final dataToSave = spots.map((spot) => {'x': spot.x, 'y': spot.y}).toList();
  final deviceStartTime = deviceStartTimes[widget.deviceId];

  // Save data and startTime for the current device
  spotBox.put('${widget.deviceId}_spots', dataToSave);
  if (deviceStartTime != null) {
    spotBox.put('${widget.deviceId}_startTime', deviceStartTime.toIso8601String());
  }
}

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer
    _saveData(); // Save data when leaving the page
    spotBox.close();
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

  void _generateLightData(Map<String, dynamic> sensorData) {
  DateTime currentTime = DateTime.now();

  // Use device manager to check device status
  final deviceManager = Provider.of<DeviceManager>(context, listen: false);
  if (sensorData.isEmpty || !deviceManager.deviceIsActive(widget.deviceId)) {
    return;
  }

  // Initialize device-specific state maps if not already present
  deviceStartTimes.putIfAbsent(widget.deviceId, () => currentTime);
  deviceStartTimeSet.putIfAbsent(widget.deviceId, () => false);

  // Set the start time for this device if not already set
  if (!deviceStartTimeSet[widget.deviceId]!) {
    deviceStartTimes[widget.deviceId] = currentTime;
    deviceStartTimeSet[widget.deviceId] = true;
  }

  // Use the device-specific start time
  DateTime deviceStartTime = deviceStartTimes[widget.deviceId]!;
  sensorData.entries
      .where((entry) => entry.key.contains('lightState'))
      .forEach((entry) {
    final lightValue = double.tryParse(entry.value.toString()) ?? 0.0;
    final timeElapsed = currentTime.difference(deviceStartTime).inMinutes.toDouble();
    final spot = FlSpot(timeElapsed, lightValue);

    spots.add(spot);
  });

  spots.sort((a, b) => a.x.compareTo(b.x));

  // Handle cycle completion for this device
  if (spots.isNotEmpty && spots.last.x >3) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        setState(() {
          final cycleId = DateTime.now().millisecondsSinceEpoch.toString();

          // Generate cycle entries specific to this device
          final List<Map<String, dynamic>> cycleEntries = spots.map((spot) {
            final timestamp = deviceStartTime.add(Duration(
                minutes: spot.x.toInt(),
                seconds: ((spot.x - spot.x.toInt()) * 60).toInt()));
            return {
              'id': cycleId,
              'time': timestamp.toIso8601String(),
              'data': spot.y,
'cycleStartTime': deviceStartTimes[widget.deviceId]?.toIso8601String() ?? DateTime.now().toIso8601String(),
              'deviceId': widget.deviceId,
            };
          }).toList();

          // Add cycle entries to persistent storage
          for (var entry in cycleEntries) {
            cycleBox.add(entry);
          }

          // Reset state for the next cycle
          deviceStartTimes[widget.deviceId] = DateTime.now();
          deviceStartTimeSet[widget.deviceId] = false;
          spots.clear();
        });

        _saveData(); // Save the cleared state of current data
      });
    }
  }
}

void announceRange(double minX, double maxX, DateTime cycleStartTime) {
  DateTime startTime = cycleStartTime.add(Duration(minutes: minX.toInt()));
  DateTime endTime = cycleStartTime.add(Duration(minutes: maxX.toInt()));

  String announcement = "You are now exploring data from ${DateFormat('hh:mm a').format(startTime)} to ${DateFormat('hh:mm a').format(endTime)}.";
  TextToSpeech.speak(announcement);
}


  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {        final sensorData = deviceManager.sensorData;
        _generateLightData(sensorData);
      final isActive = deviceManager.isDeviceActive;

        final visibleSpots = spots.where((spot) {
          return spot.x >= minX && spot.x <= maxX;
        }).toList();

        return Scaffold(
          appBar: GraphAppBar(
            deviceId: widget.deviceId,
            isDeviceActive: isActive,
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              top: 12.0,
              left: 8.0, // More space for y-axis labels
              right: 8.0, // More space for right side
              bottom: 8.0, // Less bottom padding to avoid overflow
            ),
            child: Column(
              children: [
                Expanded(
                  child: GraphContainer(
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
                              reservedSize: 48, // More space for y-axis
                              interval: 5,
                              getTitlesWidget: (value, titleMeta) {
                                return Container(
                                  alignment: Alignment.centerRight,
                                  width: 40,
                                  child: Text(
                                    '${value.toInt()}%',
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
                        maxY: 95,
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
                                  "${touchedSpot.y.toStringAsFixed(1)}% at ${DateFormat('hh:mm a').format(spotTime)}.";
                              TextToSpeech.speak(message);
                            }
                          },
                          touchTooltipData: const LineTouchTooltipData(tooltipPadding: EdgeInsets.zero),
                        ),
                      ),
                    ),
                  ),
                ),
                TimeRangeNavigator(
                  minX: minX,
                  maxX: maxX,
                  onPrevious: () {
                    setState(() {
                      if (minX > 0) {
                        minX -= 1;
                        maxX -= 1;
                      }
                    });
                  },
                  onNext: () {
                    setState(() {
                      if (maxX < 12) {
                        minX += 1;
                        maxX += 1;
                      }
                    });
                  },
                  cycleStartTime: deviceStartTimes[widget.deviceId],
                ),
                HistoricalDataButton(
                  deviceId: widget.deviceId,
                  onDateSelected: loadHistoricalCycles,
                ),

              ],
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
      child: const MaterialApp(
        home: LightVsTimeGraph(deviceId: ''), // Pass the deviceId dynamically
      ),
    ),
  );
}