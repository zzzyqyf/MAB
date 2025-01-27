import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_application_final/DeviceIdProvider.dart';
import 'package:flutter_application_final/TextToSpeech.dart';
import 'package:flutter_application_final/deviceMnanger.dart';
import 'package:flutter_application_final/mqttservice.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  double maxX = 3;
  List<FlSpot> spots = [];
  Map<String, DateTime> deviceStartTimes = {};
Map<String, bool> deviceStartTimeSet = {};

  late Box spotBox;
  late Box cycleBox;
    Map<String, dynamic> sensorData = {}; // Placeholder for sensor data
  late Timer _timer;  // Declare the timer
bool isViewingHistoricalData = false;

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
  void loadHistoricalCycles(DateTime selectedDate, String deviceId) {
    setState(() {
    isViewingHistoricalData = true; // Pause periodic updates
  });

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
     TextToSpeech.speak(
 "No cycles found for the selected date: ${DateFormat('yyyy-MM-dd').format(selectedDate)} returend back to the prevoius screen" 
     );
    /*
    setState(() {
      spots.clear();
            deviceStartTimes[deviceId] = DateTime.fromMillisecondsSinceEpoch(0); // Reset start time

       // Clear graph if no data is found
    });*/
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
void exitHistoricalView() {
  setState(() {
    isViewingHistoricalData = false; // Resume periodic updates
  });
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

 void _generateTemperatureData(Map<String, dynamic> sensorData) async {
  if (isViewingHistoricalData) return; // Skip updates

  DateTime currentTime = DateTime.now();

  // Use device manager to check device status
  final deviceManager = Provider.of<DeviceManager>(context, listen: false);
  if (sensorData.isEmpty || !deviceManager.deviceIsActive(widget.deviceId)) {
    return;
  }

  // Initialise device-specific state maps if not already present
  deviceStartTimes.putIfAbsent(widget.deviceId, () => currentTime);
  deviceStartTimeSet.putIfAbsent(widget.deviceId, () => false);

  // Set the start time for this device if not already set
  if (!deviceStartTimeSet[widget.deviceId]!) {
    deviceStartTimes[widget.deviceId] = currentTime;
    deviceStartTimeSet[widget.deviceId] = true;
  }

  // Use the device-specific start time
  DateTime deviceStartTime = deviceStartTimes[widget.deviceId]!;

  // Retrieve real-time sensor data and calculate elapsed time
  if (sensorData.containsKey('temperature')) {
    double temperature = sensorData['temperature'] ?? 0.0;
    double timeElapsed = currentTime.difference(deviceStartTime).inMinutes.toDouble();
    spots.add(FlSpot(timeElapsed, temperature));
  }

  // Sort spots to ensure proper plotting
  spots.sort((a, b) => a.x.compareTo(b.x));

  // Check if the cycle is complete
  if (spots.isNotEmpty && spots.last.x >= 3) {
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
              'cycleStartTime': deviceStartTime.toIso8601String(),
              'deviceId': widget.deviceId,
            };
          }).toList();

          // Add cycle entries to persistent storage
         // final cycleBox = await Hive.openBox<Map<String, dynamic>>('cycleData');
          for (var entry in cycleEntries) {
            cycleBox.add(entry);
          }

          // Filter spots to retain only new data
          spots = spots.where((spot) => spot.x > 3).toList();

          // Reset state for the next cycle
          deviceStartTimes[widget.deviceId] = DateTime.now();
          deviceStartTimeSet[widget.deviceId] = true;
        });

        _saveData(); // Save the cleared state of current data
      });
    }
  }

  print('Sensor Data: $sensorData');
  print('Spots: $spots');
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
 _saveData();
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
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (value, titleMeta) {
                            // Use the start time of the historical cycle if available
                            DateTime cycleStartTime = deviceStartTimes[widget.deviceId] ?? DateTime.now();

                            // Add the elapsed time (value in minutes) to the cycle start time
                            DateTime xTime = cycleStartTime.add(Duration(minutes: value.toInt()));

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('HH:mm').format(xTime), // Format time as HH:mm
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
                    lineTouchData: LineTouchData(
                      touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                        if (event is FlTapUpEvent && response != null && response.lineBarSpots != null) {
                          final touchedSpot = response.lineBarSpots!.first;
                          final DateTime spotTime = deviceStartTimes[widget.deviceId]!
                              .add(Duration(minutes: touchedSpot.x.toInt()));
                          final String message =
                              "${touchedSpot.y.toStringAsFixed(1)}°C at ${DateFormat('hh:mm a').format(spotTime)}.";
                          TextToSpeech.speak(message); // Call the TextToSpeech method to announce data
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(tooltipBgColor: Colors.transparent), // Disable visual tooltips
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
  icon: Icon(Icons.arrow_back),
  onPressed: () {
    setState(() {
      if (minX > 0) {
        minX -= 1;
        maxX -= 1;
      }
      // Always announce the range, regardless of conditions
      announceRange(minX, maxX, deviceStartTimes[widget.deviceId]!);
    });
  },
),

                      Text('Scroll Time Range: $minX - $maxX minutes'),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
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
          // Show a date picker to the user
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1970), // Adjust as needed
            lastDate: DateTime.now(),
          );

          if (pickedDate != null) {
            loadHistoricalCycles(pickedDate,widget.deviceId); // Load data for the selected date
          }
        },
        child: Text("Load Historical Cycles for Date"),
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