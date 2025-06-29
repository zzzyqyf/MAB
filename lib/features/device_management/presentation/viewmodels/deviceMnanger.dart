import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../shared/services/mqttservice.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DeviceManager extends ChangeNotifier {
  bool _isDeviceActive = false;
  Box? _deviceBox;
  final Map<String, MqttService> _mqttServices = {};
  final Map<String, Timer> _inactivityTimers = {};
  final double temperatureThreshold = 32.0;
  final double humidityThreshold = 20.0;
  final int criticalDuration = 10;
  Box<Map<String, dynamic>>? _sensorBox;
  DateTime? tempThresholdStartTime;
  DateTime? humidityThresholdStartTime;
  Map<String, dynamic> _sensorData = {};
  Map<String, dynamic> get sensorData => _sensorData;
  bool get isDeviceActive => _isDeviceActive;
  
  // For notifications
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  DeviceManager() {
    initHive();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Box? get deviceBox => _deviceBox;

  List<Map<String, dynamic>> get devices {
    if (_deviceBox != null && _deviceBox!.isOpen) {
      return _deviceBox!.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
  
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  void toggleMute(bool value) {
    _isMuted = value;
    notifyListeners();
  }

  Map<String, dynamic>? getDeviceById(String deviceId) {
    print("DeviceManager: Looking up device with ID: $deviceId");
    
    // Check if device box is available
    if (_deviceBox == null || !_deviceBox!.isOpen) {
      print("DeviceManager: Device box not available");
      return null;
    }
    
    // Attempt to get the device by ID
    final device = _deviceBox?.get(deviceId);
    
    if (device != null) {
      print("DeviceManager: Found device: $deviceId - ${device['name']}");
      return Map<String, dynamic>.from(device);
    } else {
      print("DeviceManager: Device not found: $deviceId");
      
      // Log all available devices for debugging
      print("DeviceManager: Available devices: ${_deviceBox!.keys.toList()}");
      
      return null;
    }
  }

  String _deviceId = '';
  String get deviceId => _deviceId;

  void setDeviceId(String id) {
    final device = _deviceBox?.get(id);
    if (device != null) {
      final Id = device['id'];
      _deviceId = Id;
      notifyListeners();
    }
  }

  Future<void> initHive() async {
    try {
      print("DeviceManager: Initializing Hive...");
      
      // Initialize Hive
      await Hive.initFlutter();
      
      // Open devices box
      print("DeviceManager: Opening devices box...");
      _deviceBox = await Hive.openBox('devices');
      print("DeviceManager: Devices box opened. Contains ${_deviceBox?.length ?? 0} devices");
      
      // Open cycle box
      await openCycleBox();
      
      // Initialize MQTT for each device
      if (_deviceBox != null && _deviceBox!.isOpen) {
        print("DeviceManager: Initializing MQTT for ${_deviceBox!.length} devices");
        for (var device in _deviceBox!.values) {
          final deviceId = device['id'];
          print("DeviceManager: Setting up device: $deviceId - ${device['name']}");
          _initMqtt(deviceId);
          _startPeriodicStatusCheck(deviceId);
        }
      }
      
      // Handle sensor data box separately
      print("DeviceManager: Setting up sensor data box...");
      try {
        await Hive.deleteBoxFromDisk('sensorData');
      } catch (e) {
        print("DeviceManager: Error deleting sensorData box: $e");
        // Continue anyway
      }
      
      // Re-initialize Hive to ensure clean state
      _sensorBox = await Hive.openBox<Map<String, dynamic>>('sensorData');
      print("DeviceManager: Sensor data box initialized");
      
      print("DeviceManager: Hive initialization complete");
    } catch (e) {
      print("DeviceManager ERROR: Failed to initialize Hive: $e");
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> getSensorDataForDevice(String deviceId) {
    if (_sensorBox != null && _sensorBox!.isOpen) {
      return _sensorBox!.values
          .where((entry) => entry['deviceId'] == deviceId)
          .toList();
    }
    return [];
  }

  late Box<Map<String, dynamic>> cycleBox;

  Future<void> openCycleBox() async {
    cycleBox = await Hive.openBox<Map<String, dynamic>>('cycleBox');
  }

  void _initMqtt(String deviceId) {
    print("Initializing MqttService for $deviceId");

    final mqttService = MqttService(
      id: deviceId,
      onDataReceived: (temperature, humidity, lightState) {
        storeSensorData(deviceId, temperature!, DateTime.now());
        print("Data received: Temp=$temperature, Humidity=$humidity, Light=$lightState");
        _sensorData = {
          'deviceId': deviceId,
          'temperature': temperature,
          'humidity': humidity,
          'lightState': lightState,
        };
        notifyListeners();
        
        _markDeviceOnline(deviceId);
        _updateDisconnectionTime(deviceId, DateTime.now(), 'online');
        monitorSensors(temperature, humidity, deviceId);
      },
      onDeviceConnectionStatusChange: (deviceId, status) {
        updateDeviceStatus(deviceId, status);
      },
    );

    _mqttServices[deviceId] = mqttService;
    mqttService.setupMqttClient();
  }

  void _startPeriodicStatusCheck(String deviceId) {
    _inactivityTimers[deviceId] = Timer.periodic(const Duration(seconds: 5), (timer) {
      final mqttService = _mqttServices[deviceId];
      if (mqttService == null) {
        timer.cancel();
        return;
      }
      
      final isDataReceived = mqttService.isDataReceived(deviceId);
      print("Periodic check for device $deviceId: isDataReceived=$isDataReceived");

      if (!isDataReceived) {
        updateDeviceStatus(deviceId, 'offline');
        displayCriticalStatus("no data", deviceId);
        _updateDisconnectionTime(deviceId, DateTime.now(), 'offline');
      }
    });
  }

  void updateDeviceStatus(String deviceId, String newStatus) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      device['status'] = newStatus;
      if (newStatus == 'offline') {
        device['sensorStatus'] = 'no data';
      }
      _deviceBox?.put(deviceId, device);
      deviceIsActive(deviceId);
    }
  }

  void _markDeviceOnline(String deviceId) {
    updateDeviceStatus(deviceId, 'online');
  }

  bool deviceIsActive(String deviceId) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      final status = device['status'];
      final sensorStatus = device['sensorStatus'];
      final isActive = status == 'online' && sensorStatus != 'no data';
      _isDeviceActive = isActive;
      notifyListeners();
      return isActive;
    }
    _isDeviceActive = false;
    notifyListeners();
    return false;
  }

  Future<void> storeSensorData(String deviceId, double temperature, DateTime timestamp) async {
    final sensorBox = await Hive.openBox<Map<String, dynamic>>('sensorData');
    try {
      if (sensorBox.isNotEmpty) {
        final lastStoredData = sensorBox.values.last;
        final lastTimestamp = DateTime.parse(lastStoredData['timestamp']);
        if (lastTimestamp.minute == timestamp.minute && lastTimestamp.hour == timestamp.hour) {
          print('Timestamp is the same as the last one. Data not stored.');
          return;
        }
      }

      final sensorData = {
        'deviceId': deviceId,
        'temperature': temperature,
        'timestamp': timestamp.toIso8601String(),
      };

      sensorBox.add(Map<String, dynamic>.from(sensorData));
      print('Stored Data: ${sensorBox.values.toList()}');
    } catch (e) {
      print('Error storing sensor data: $e');
    }
    notifyListeners();
  }

  bool isCritical = false;

  void monitorSensors(double? temp, double? humidity, String deviceId) {
    final now = DateTime.now();
    bool isTempCritical = false;
    bool isHumidityCritical = false;

    if (temp == null) {
      displayCriticalStatus("no data in temperature", deviceId);
    } else if (temp > temperatureThreshold) {
      tempThresholdStartTime ??= now;
      if (now.difference(tempThresholdStartTime!).inSeconds >= criticalDuration) {
        isTempCritical = true;
      }
    } else {
      tempThresholdStartTime = null;
    }

    if (humidity == null) {
      displayCriticalStatus("no data", deviceId);
    } else if (humidity < humidityThreshold) {
      humidityThresholdStartTime ??= now;
      if (now.difference(humidityThresholdStartTime!).inSeconds >= criticalDuration) {
        isHumidityCritical = true;
      }
    } else {
      humidityThresholdStartTime = null;
    }

    if (isTempCritical) {
      displayCriticalStatus("High Temperature", deviceId);
      frequency("High Temperature", deviceId);
    }
    if (isHumidityCritical) {
      displayCriticalStatus("Low Humidity", deviceId);
      frequency("Low Humidity", deviceId);
    }
  }

  void displayCriticalStatus(String sensorType, String deviceId) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      if (device['sensorStatus'] != sensorType) {
        device['sensorStatus'] = sensorType;
        _deviceBox?.put(deviceId, device);
        print("Sensor status updated to $sensorType for device $deviceId.");
        frequency(sensorType, deviceId);
        notifyListeners();
      }
    } else {
      print("Device not found for ID: $deviceId.");
    }
  }

  Map<String, DateTime> lastNotificationTime = {};

  void frequency(String sensorType, String deviceId) {
    final now = DateTime.now();
    final lastTime = lastNotificationTime[deviceId] ?? DateTime(2000);

    if (now.difference(lastTime).inMinutes < 1) {
      return;
    }

    lastNotificationTime[deviceId] = now;
    showNotification(deviceId, " $sensorType");
  }

  Future<void> showNotification(String deviceId, String message) async {
    final device = _deviceBox?.get(deviceId);
    final deviceName = device != null && device['name'] != null ? device['name'] : 'Unnamed';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'critical_status_channel',
      'Critical Status Notifications',
      channelDescription: 'Notifications for critical device statuses',
      importance: Importance.low,
      priority: Priority.low,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    if (!isMuted) {
      await flutterLocalNotificationsPlugin.show(
        deviceId.hashCode,
        '$deviceName',
        message,
        platformDetails,
        payload: 'device_$deviceId',
      );
    }
    
    final notificationsBox = Hive.box('notificationsBox');
    notificationsBox.add({
      'title': ' $deviceName Device',
      'message': message,
      'timestamp': DateTime.now().toString(),
      'id': deviceId,
    });
  }

  Map<String, DateTime> deviceStartTimes = {};
  Map<String, bool> deviceStartTimeSet = {};
  List<FlSpot> spots = [];
  Map<String, int> deviceCycle = {};

  void generateTemperatureData(String deviceId, Map<String, dynamic> sensorData) {
    DateTime currentTime = DateTime.now();

    if (sensorData.isEmpty || !deviceIsActive(deviceId)) {
      return;
    }

    deviceStartTimes.putIfAbsent(deviceId, () => currentTime);
    deviceStartTimeSet.putIfAbsent(deviceId, () => false);

    if (!deviceStartTimeSet[deviceId]!) {
      deviceStartTimes[deviceId] = currentTime;
      deviceStartTimeSet[deviceId] = true;
    }

    DateTime deviceStartTime = deviceStartTimes[deviceId]!;
    final List<Map<String, dynamic>> cycleDataBuffer = [];

    sensorData.entries
        .where((entry) => entry.key.contains('temperature'))
        .forEach((entry) {
      final temperature = double.tryParse(entry.value.toString()) ?? 0.0;
      final timeElapsed = currentTime.difference(deviceStartTime).inMinutes.toDouble();

      cycleDataBuffer.add({
        'timeElapsed': timeElapsed,
        'temperature': temperature,
        'deviceId': deviceId,
      });
    });

    if (cycleDataBuffer.isNotEmpty && cycleDataBuffer.last['timeElapsed'] > 12) {
      for (var entry in cycleDataBuffer) {
        cycleBox.add(entry);
      }

      deviceStartTimes[deviceId] = DateTime.now();
      deviceStartTimeSet[deviceId] = false;
      cycleDataBuffer.clear();
      notifyListeners();
    }
  }

  void updateGraph(String deviceId) {
    final List<FlSpot> newGraphData = cycleBox.values
        .where((entry) => entry['deviceId'] == deviceId)
        .map<FlSpot>((entry) {
          return FlSpot(
            (entry['timeElapsed'] as num).toDouble(),
            (entry['temperature'] as num).toDouble(),
          );
        }).toList();

    newGraphData.sort((a, b) => a.x.compareTo(b.x));

    for (var newSpot in newGraphData) {
      if (!spots.any((existingSpot) => existingSpot.x == newSpot.x)) {
        spots.add(newSpot);
      }
    }

    spots.sort((a, b) => a.x.compareTo(b.x));
    notifyListeners();
  }

  Future<void> deleteNotificationsByDeviceId(String deviceId) async {
    final notificationsBox = Hive.box('notificationsBox');
    final notificationsToDelete = notificationsBox.values.toList().where((notification) {
      return notification['id'] == deviceId;
    }).toList();

    if (notificationsToDelete.isNotEmpty) {
      for (var notification in notificationsToDelete) {
        final index = notificationsBox.values.toList().indexOf(notification);
        await notificationsBox.deleteAt(index);
      }
      print('All notifications for device $deviceId deleted.');
    } else {
      print('No notifications found for device $deviceId.');
    }
  }

  void addDevice(String name) {
    print("DeviceManager: Adding device with name: $name");
    
    try {
      // Make sure Hive is initialized
      if (_deviceBox == null || !_deviceBox!.isOpen) {
        print("DeviceManager: Device box not initialized, reinitializing Hive");
        // We'll continue anyway, but log the issue
      }
      
      final uuid = Uuid();
      final deviceId = uuid.v4();
      final device = {
        'id': deviceId,
        'name': name.isEmpty ? 'Unnamed' : name,
        'status': 'connecting',
        'sensorStatus': '',
        'disconnectionTimeResult': 'not connected yet!',
      };
      
      print("DeviceManager: Creating device with ID: $deviceId and name: $name");
      
      // Add to Hive box if available
      _deviceBox?.put(deviceId, device);
      
      print("DeviceManager: Device added to Hive box");
      print("DeviceManager: Current devices count: ${_deviceBox?.length ?? 0}");
      
      // Notify listeners of the change
      notifyListeners();
      print("DeviceManager: Notified listeners");

      // Initialize MQTT for the new device
      _initMqtt(deviceId);

      // Set a timer to update device status if it remains in connecting state
      Timer(Duration(seconds: 5), () {
        if (_deviceBox?.get(deviceId)?['status'] == 'connecting') {
          updateDeviceStatus(deviceId, 'offline');
        }
        if (_deviceBox?.get(deviceId)?['status'] == 'offline') {
          displayCriticalStatus("no data", deviceId);
        }
        _startPeriodicStatusCheck(deviceId);
        
        // Notify listeners again after status update
        notifyListeners();
      });
    } catch (e) {
      print("DeviceManager ERROR: Failed to add device: $e");
      // Still notify listeners even if there was an error
      notifyListeners();
    }
  }

  void removeDevice(String deviceId) {
    _mqttServices[deviceId]?.dispose();
    _mqttServices.remove(deviceId);
    _inactivityTimers[deviceId]?.cancel();
    _inactivityTimers.remove(deviceId);
    lastNotificationTime.remove(deviceId);
    _deviceBox?.delete(deviceId);
    deleteNotificationsByDeviceId(deviceId);
    notifyListeners();
  }

  void updateDeviceName(String deviceId, String newName) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      device['name'] = newName;
      _deviceBox?.put(deviceId, device);
      notifyListeners();
    }
  }

  Map<String, dynamic>? getDeviceData(String deviceId) {
    final device = _deviceBox?.get(deviceId);
    return device is Map<String, dynamic> ? device : null;
  }

  void _updateDisconnectionTime(String deviceId, DateTime timestamp, String newStatus) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      if (newStatus == 'offline' && device['disconnectionTimeResult'] == 'online') {
        device['disconnectionTimestamp'] = timestamp.toLocal().toString();
        device['disconnectionTimeResult'] = 'offline';
        print("$deviceId was disconnected at: ${device['disconnectionTimestamp']}");
      } else if (newStatus == 'online') {
        device['disconnectionTimeResult'] = 'online';
        print("$deviceId is now connected.");
      }
      _deviceBox?.put(deviceId, device);
      notifyListeners();
    }
  }

  String getDisconnectionTime(String deviceId) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      final result = device['disconnectionTimeResult'] ?? 'online';
      if (result == 'online') {
        return 'Connected';
      }
      final timestamp = device['disconnectionTimestamp'] ?? 'N/A';
      return "Disconnected at $timestamp";
    }
    return 'No data available';
  }

  void initializeDevices() {
    if (_deviceBox != null) {
      _deviceBox?.toMap().forEach((deviceId, deviceData) {
        final status = deviceData['disconnectionTimeResult'] ?? 'connected';
        final timestamp = deviceData['disconnectionTimestamp'] ?? 'N/A';
        print("Device $deviceId is $status. Last disconnected at: $timestamp");
      });
    }
  }
}