import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../shared/services/TextToSpeech.dart';
import '../../../features/device_management/presentation/viewmodels/deviceManager.dart';
import 'graph_components.dart';

/// Abstract Graph Factory implementing the Factory Pattern
/// This creates different types of graphs based on sensor types
abstract class GraphFactory {
  static BaseGraphWidget createGraph({
    required String deviceId,
    required GraphType type,
  }) {
    switch (type) {
      case GraphType.temperature:
        return TemperatureGraphWidget(deviceId: deviceId);
      case GraphType.humidity:
        return HumidityGraphWidget(deviceId: deviceId);
      case GraphType.light:
        return LightGraphWidget(deviceId: deviceId);
    }
  }
}

/// Enum defining graph types for type safety
enum GraphType { temperature, humidity, light }

/// Interface for graph configuration
abstract class IGraphConfiguration {
  String get dataKey;
  String get unit;
  String get boxName;
  String get cycleBoxName;
  Color get primaryColor;
  double get maxY;
  String get title;
}

/// Configuration classes implementing the configuration interface
class TemperatureGraphConfig implements IGraphConfiguration {
  @override
  String get dataKey => 'humidity'; // Note: This seems to be temperature data stored under humidity key
  @override
  String get unit => '%';
  @override
  String get boxName => 'htemperatureData';
  @override
  String get cycleBoxName => 'hcycleData';
  @override
  Color get primaryColor => Colors.red;
  @override
  double get maxY => 95;
  @override
  String get title => 'Temperature';
}

class HumidityGraphConfig implements IGraphConfiguration {
  @override
  String get dataKey => 'humidity';
  @override
  String get unit => '%';
  @override
  String get boxName => 'humidityData';
  @override
  String get cycleBoxName => 'humidityMCycleData';
  @override
  Color get primaryColor => Colors.blue;
  @override
  double get maxY => 95;
  @override
  String get title => 'Humidity';
}

class LightGraphConfig implements IGraphConfiguration {
  @override
  String get dataKey => 'lightState';
  @override
  String get unit => '%';
  @override
  String get boxName => 'lightData';
  @override
  String get cycleBoxName => 'lightCycleData';
  @override
  Color get primaryColor => Colors.orange;
  @override
  double get maxY => 95;
  @override
  String get title => 'Light';
}

/// Abstract base widget class for all graph widgets
abstract class BaseGraphWidget extends StatefulWidget {
  final String deviceId;
  
  const BaseGraphWidget({super.key, required this.deviceId});
  
  @override
  BaseGraphState createState();
  
  // Abstract method to get configuration
  IGraphConfiguration get configuration;
}

/// Abstract base state class implementing common graph functionality
abstract class BaseGraphState<T extends BaseGraphWidget> extends State<T> {
  // Common state variables
  double minX = 0;
  double maxX = 3;
  List<FlSpot> spots = [];
  Map<String, DateTime> deviceStartTimes = {};
  Map<String, bool> deviceStartTimeSet = {};
  late Box spotBox;
  late Box cycleBox;
  Map<String, dynamic> sensorData = {};
  late Timer _timer;
  
  // Abstract getter for configuration
  IGraphConfiguration get config => widget.configuration;
  
  @override
  void initState() {
    super.initState();
    _initializeGraph();
  }
  
  Future<void> _initializeGraph() async {
    await _initializeHive();
    _startPeriodicCheck();
  }
  
  Future<void> _initializeHive() async {
    spotBox = await Hive.openBox(config.boxName);
    cycleBox = await Hive.openBox(config.cycleBoxName);
    _loadData();
  }
  
  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _generateData(sensorData);
    });
  }
  
  void _loadData() {
    final storedData = spotBox.get('${widget.deviceId}_spots', defaultValue: []);
    final storedStartTime = spotBox.get('${widget.deviceId}_startTime', defaultValue: DateTime.now().toIso8601String());

    setState(() {
      spots = (storedData as List<dynamic>)
          .map((item) => FlSpot(item['x'], item['y']))
          .toList();
      deviceStartTimes[widget.deviceId] = DateTime.parse(storedStartTime);
      deviceStartTimeSet[widget.deviceId] = true;
    });
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
  
  void _generateData(Map<String, dynamic> sensorData) {
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
        .where((entry) => entry.key.contains(config.dataKey))
        .forEach((entry) {
      final value = double.tryParse(entry.value.toString()) ?? 0.0;
      final timeElapsed = currentTime.difference(deviceStartTime).inMinutes.toDouble();
      final spot = FlSpot(timeElapsed, value);
      spots.add(spot);
    });

    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.isNotEmpty && spots.last.x > 3) {
      _handleCycleCompletion(deviceStartTime);
    }
  }
  
  void _handleCycleCompletion(DateTime deviceStartTime) {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        setState(() {
          final cycleId = DateTime.now().millisecondsSinceEpoch.toString();

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

          for (var entry in cycleEntries) {
            cycleBox.add(entry);
          }

          deviceStartTimes[widget.deviceId] = DateTime.now();
          deviceStartTimeSet[widget.deviceId] = false;
          spots.clear();
        });

        _saveData();
      });
    }
  }
  
  void loadHistoricalCycles(DateTime selectedDate, String deviceId) {
    final allCycles = cycleBox.values.toList();

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
        deviceStartTimes[deviceId] = DateTime.fromMillisecondsSinceEpoch(0);
      });
    } else {
      final firstCycleStartTime = DateTime.parse(filteredCycles.first['cycleStartTime']);

      setState(() {
        deviceStartTimes[deviceId] = firstCycleStartTime;
        spots = filteredCycles.map((cycle) {
          final xTime = DateTime.parse(cycle['time']);
          final xElapsed = xTime.difference(firstCycleStartTime).inMinutes.toDouble();
          return FlSpot(xElapsed, cycle['data'].toDouble());
        }).toList();

        spots.sort((a, b) => a.x.compareTo(b.x));
      });
    }
  }
  
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
  
  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {
        final sensorData = deviceManager.sensorData;
        _generateData(sensorData);
        final isActive = deviceManager.isDeviceActive;

        final visibleSpots = spots.where((spot) {
          return spot.x >= minX && spot.x <= maxX;
        }).toList();

        return Scaffold(
          appBar: GraphAppBar(
            deviceId: widget.deviceId,
            isDeviceActive: isActive,
            title: config.title,
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
                  child: GraphContainer(
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: _buildTitlesData(),
                        borderData: FlBorderData(show: true),
                        minX: minX,
                        maxX: maxX,
                        minY: 0,
                        maxY: config.maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: visibleSpots,
                            isCurved: true,
                            color: config.primaryColor,
                            belowBarData: BarAreaData(
                              show: true,
                              color: config.primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchCallback: _onTouchCallback,
                          touchTooltipData: const LineTouchTooltipData(tooltipPadding: EdgeInsets.zero),
                        ),
                      ),
                    ),
                  ),
                ),
                TimeRangeNavigator(
                  minX: minX,
                  maxX: maxX,
                  onPrevious: navigatePrevious,
                  onNext: navigateNext,
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
  
  FlTitlesData _buildTitlesData() {
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
                '${value.toInt()}${config.unit}',
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
  
  void _onTouchCallback(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlTapUpEvent && response != null && response.lineBarSpots != null) {
      final touchedSpot = response.lineBarSpots!.first;
      final DateTime spotTime = deviceStartTimes[widget.deviceId]!
          .add(Duration(minutes: touchedSpot.x.toInt()));
      final String message =
          "${touchedSpot.y.toStringAsFixed(1)}${config.unit} at ${DateFormat('hh:mm a').format(spotTime)}.";
      TextToSpeech.speak(message);
    }
  }
}

/// Concrete implementations of graph widgets
class TemperatureGraphWidget extends BaseGraphWidget {
  const TemperatureGraphWidget({super.key, required super.deviceId});
  
  @override
  IGraphConfiguration get configuration => TemperatureGraphConfig();
  
  @override
  BaseGraphState createState() => _TemperatureGraphState();
}

class _TemperatureGraphState extends BaseGraphState<TemperatureGraphWidget> {}

class HumidityGraphWidget extends BaseGraphWidget {
  const HumidityGraphWidget({super.key, required super.deviceId});
  
  @override
  IGraphConfiguration get configuration => HumidityGraphConfig();
  
  @override
  BaseGraphState createState() => _HumidityGraphState();
}

class _HumidityGraphState extends BaseGraphState<HumidityGraphWidget> {}

class LightGraphWidget extends BaseGraphWidget {
  const LightGraphWidget({super.key, required super.deviceId});
  
  @override
  IGraphConfiguration get configuration => LightGraphConfig();
  
  @override
  BaseGraphState createState() => _LightGraphState();
}

class _LightGraphState extends BaseGraphState<LightGraphWidget> {}
