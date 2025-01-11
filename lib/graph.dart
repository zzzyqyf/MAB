import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_final/DeviceIdProvider.dart';
import 'package:flutter_application_final/deviceMnanger.dart';
import 'package:flutter_application_final/mqttservice.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TempVsTimeGraph extends StatefulWidget {
  final String deviceId; // The deviceId will be passed dynamically

  TempVsTimeGraph({required this.deviceId});

  @override
  _TempVsTimeGraphState createState() => _TempVsTimeGraphState();
}

class _TempVsTimeGraphState extends State<TempVsTimeGraph> {
  double minX = 0;
  double maxX = 6;
  List<FlSpot> spots = [];
  DateTime startTime = DateTime.now();
  bool isStartTimeSet = false;
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

  }

  Future<void> _initializeHive() async {
    spotBox = await Hive.openBox('temperatureData');
    cycleBox = await Hive.openBox('cycleData');  // New box for completed cycles
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
  void loadHistoricalCycles() {
    int counter = 0;
    final allCycles = cycleBox.values.toList(); // Retrieve all stored cycles
    for (var cycle in allCycles) {
      print(cycle);
      counter++; // Each cycle is a List of {time, data} maps
    }
  }

  void _loadData() {
    //what does this do   final storedData = spotBox.get('spots', defaultValue: []);
  final storedData = spotBox.get('spots', defaultValue: []);
  final storedStartTime = spotBox.get('startTime', defaultValue: DateTime.now().toIso8601String());

  setState(() {
    spots = (storedData as List<dynamic>)
        .map((item) => FlSpot(item['x'], item['y']))
        .toList();
    startTime = DateTime.parse(storedStartTime);

    
  });
}


  void _saveData() {
  final dataToSave = spots.map((spot) => {'x': spot.x, 'y': spot.y}).toList();
  //final cyclesToSave = historicalCycles.map((cycle) => cycle.map((spot) => {'x': spot.x, 'y': spot.y}).toList()).toList();
  spotBox.put('spots', dataToSave);
  spotBox.put('startTime', startTime.toIso8601String());
  //spotBox.put('historicalCycles', cyclesToSave);  // Save the historical cycles
}

  @override
  void dispose() {
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

//ask chatgpt of they start generating in the first place
  void _generateTemperatureData(Map<String, dynamic> sensorData) {
  DateTime currentTime = DateTime.now();

  // Use device manager to check device status
  final deviceManager = Provider.of<DeviceManager>(context, listen: false);
  if (sensorData.isEmpty || !deviceManager.deviceIsActive(widget.deviceId)) { // Check device status
    return;
  }

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

    spots.add(spot);
  });

  spots.sort((a, b) => a.x.compareTo(b.x));
  if (spots.isNotEmpty && spots.last.x > 3) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        setState(() {
          final cycleId = DateTime.now().millisecondsSinceEpoch.toString();

          final List<Map<String, dynamic>> cycleEntries = spots.map((spot) {
            final timestamp = startTime.add(Duration(
                minutes: spot.x.toInt(),
                seconds: ((spot.x - spot.x.toInt()) * 60).toInt()));
            return {
              'id': cycleId,
              'time': timestamp.toIso8601String(),
              'data': spot.y,
              'cycleStartTime': startTime.toIso8601String(),
              'deviceId': widget.deviceId,
            };
          }).toList();

          for (var entry in cycleEntries) {
            cycleBox.add(entry);
          }

          startTime = DateTime.now();
          isStartTimeSet = false;
          spots.clear();
        });

        _saveData(); // Save the cleared state of current data
      });
    }
  }
}

  

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {
        final sensorData = deviceManager.sensorData;
        _generateTemperatureData(sensorData);
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
              bottom: 300.0,
            ),
            child: Column(
              children: [
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 1,
                            getTitlesWidget: (value, titleMeta) {
                              DateTime xTime = startTime.add(Duration(minutes: value.toInt()));
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  formatTime(xTime),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
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
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
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
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () {
                          setState(() {
                            if (maxX < 24) {
                              minX += 1;
                              maxX += 1;
                            }
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
                        onPressed: () {
                          loadHistoricalCycles(); // Trigger the method
                        },
                        child: Text("Load Historical Cycles"),
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

void main() async {
  await Hive.initFlutter();
  runApp(
    ChangeNotifierProvider(
      create: (_) => DeviceManager(),
      child: MaterialApp(
        home: TempVsTimeGraph(deviceId: ''), // Pass the deviceId dynamically
      ),
    ),
  );
}
