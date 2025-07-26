import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../shared/services/mqttservice.dart';
import '../../../../shared/services/mqtt_manager.dart';
import '../../../../shared/services/device_discovery_service.dart';
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
  
  // Device discovery service
  DeviceDiscoveryService? _discoveryService;
  
  Map<String, dynamic> get sensorData => _sensorData;
  bool get isDeviceActive => _isDeviceActive;
  DeviceDiscoveryService? get discoveryService => _discoveryService;

  /// Get sensor data for a specific device
  Map<String, dynamic> getSensorDataForDeviceId(String deviceId) {
    // First try with device ID (UUID)
    if (_sensorData.containsKey(deviceId)) {
      return _sensorData[deviceId] ?? {};
    }
    
    // Then try with MQTT ID (device name) by finding the device in the stored devices
    final deviceList = devices; // This returns List<Map<String, dynamic>>
    final device = deviceList.firstWhere(
      (d) => d['id'] == deviceId,
      orElse: () => <String, dynamic>{},
    );
    
    if (device.isNotEmpty && device['mqttId'] != null && _sensorData.containsKey(device['mqttId'])) {
      return _sensorData[device['mqttId']] ?? {};
    }
    
    return {};
  }
  
  // For notifications
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  DeviceManager() {
    initHive();
    _initializeServices();
    _initializeNotifications();
  }

  Future<void> _initializeServices() async {
    // Initialize MQTT Manager
    await MqttManager.instance.initialize();
    
    // Initialize Device Discovery Service
    _discoveryService = DeviceDiscoveryService();
    
    // Listen to device discovery events
    _discoveryService?.deviceRegistered.listen(_onDeviceDiscovered);
    _discoveryService?.deviceUnregistered.listen(_onDeviceUnregistered);
  }

  void _onDeviceDiscovered(DeviceInfo deviceInfo) {
    debugPrint('DeviceManager: New device discovered: ${deviceInfo.deviceId}');
    // Optionally auto-add discovered devices or notify UI
    notifyListeners();
  }

  void _onDeviceUnregistered(String deviceId) {
    debugPrint('DeviceManager: Device unregistered: $deviceId');
    // Handle device removal
    notifyListeners();
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
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      return Map<String, dynamic>.from(device);
    }
    return null;
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
    await Hive.initFlutter();
    _deviceBox = await Hive.openBox('devices');
    openCycleBox();
    if (_deviceBox != null) {
      for (var device in _deviceBox!.values) {
        final deviceId = device['id'];
        // Use MQTT ID if available, otherwise fall back to device name or ID
        final mqttId = device['mqttId'] ?? device['name'] ?? deviceId;
        _initMqtt(mqttId);
        _startPeriodicStatusCheck(mqttId);
      }
    }
    await Hive.deleteBoxFromDisk('sensorData');
    await Hive.initFlutter();
    _sensorBox = await Hive.openBox<Map<String, dynamic>>('sensorData');
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
    if (kDebugMode) {
      debugPrint("🔌 Initializing MqttService for $deviceId");
    }

    final mqttService = MqttService(
      deviceId: deviceId,
      onDataReceived: (temperature, humidity, lightState, blueLightState, co2Level, moisture,
                      temperatureTimestamp, humidityTimestamp, lightTimestamp, blueLightTimestamp, co2Timestamp, moistureTimestamp) {
        if (temperature != null) storeSensorData(deviceId, temperature, DateTime.now());
        
        debugPrint("🔄 DeviceManager: Updating sensor data for $deviceId");
        debugPrint("   🌡️ Temperature: $temperature°C");
        debugPrint("   💧 Humidity: $humidity%");
        debugPrint("   💡 Light: ${lightState == 1 ? 'ON' : lightState == 0 ? 'OFF' : '--'}");
        debugPrint("   🔵 Blue Light: $blueLightState lux");
        debugPrint("   🌫️ CO2: $co2Level ppm");
        debugPrint("   🌱 Moisture: $moisture%");
        
        // Update the sensor data map properly
        _updateSensorData(
          deviceId, temperature, humidity, lightState, blueLightState, co2Level, moisture,
          temperatureTimestamp, humidityTimestamp, lightTimestamp, blueLightTimestamp, co2Timestamp, moistureTimestamp
        );
        
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

  void _updateSensorData(String deviceId, double? temp, double? humidity, int? lightState, int? blueLightState, double? co2Level, double? moisture,
                         int? tempTimestamp, int? humidityTimestamp, int? lightTimestamp, int? blueLightTimestamp, int? co2Timestamp, int? moistureTimestamp) {
    debugPrint('🔄 DeviceManager: Updating sensor data for $deviceId');
    
    // Initialize sensor data map if needed
    if (_sensorData[deviceId] == null) {
      _sensorData[deviceId] = <String, dynamic>{};
    }

    bool hasUpdates = false;

    // Update only if values have changed
    if (temp != null && _sensorData[deviceId]!['temperature'] != temp) {
      _sensorData[deviceId]!['temperature'] = temp;
      if (tempTimestamp != null) _sensorData[deviceId]!['temperatureTimestamp'] = tempTimestamp;
      hasUpdates = true;
      debugPrint('   🌡️ Temperature: $temp°C');
    }
    
    if (humidity != null && _sensorData[deviceId]!['humidity'] != humidity) {
      _sensorData[deviceId]!['humidity'] = humidity;
      if (humidityTimestamp != null) _sensorData[deviceId]!['humidityTimestamp'] = humidityTimestamp;
      hasUpdates = true;
      debugPrint('   💧 Humidity: $humidity%');
    }
    
    if (lightState != null && _sensorData[deviceId]!['lightState'] != lightState) {
      _sensorData[deviceId]!['lightState'] = lightState;
      if (lightTimestamp != null) _sensorData[deviceId]!['lightTimestamp'] = lightTimestamp;
      hasUpdates = true;
      debugPrint('   💡 Light: $lightState lux');
    }
    
    if (blueLightState != null && _sensorData[deviceId]!['blueLightState'] != blueLightState) {
      _sensorData[deviceId]!['blueLightState'] = blueLightState;
      if (blueLightTimestamp != null) _sensorData[deviceId]!['blueLightTimestamp'] = blueLightTimestamp;
      hasUpdates = true;
      debugPrint('   🔵 Blue Light: $blueLightState lux');
    }
    
    if (co2Level != null && _sensorData[deviceId]!['co2Level'] != co2Level) {
      _sensorData[deviceId]!['co2Level'] = co2Level;
      if (co2Timestamp != null) _sensorData[deviceId]!['co2Timestamp'] = co2Timestamp;
      hasUpdates = true;
      debugPrint('   🌫️ CO2: $co2Level ppm');
    }
    
    if (moisture != null && _sensorData[deviceId]!['moisture'] != moisture) {
      _sensorData[deviceId]!['moisture'] = moisture;
      if (moistureTimestamp != null) _sensorData[deviceId]!['moistureTimestamp'] = moistureTimestamp;
      hasUpdates = true;
      debugPrint('   🌱 Moisture: $moisture%');
    }

    if (hasUpdates) {
      _sensorData[deviceId]!['lastUpdate'] = DateTime.now().millisecondsSinceEpoch;
      
      // ✅ CRITICAL FIX: Update the device's sensorStatus in Hive storage
      _updateDeviceSensorStatus(deviceId, 'online');
      
      debugPrint('✅ DeviceManager: Sensor data updated, notifying listeners...');
      notifyListeners(); // CRITICAL: Trigger UI rebuild
    }
  }
  
  // ✅ New method to update device sensorStatus in Hive
  void _updateDeviceSensorStatus(String deviceId, String sensorStatus) {
    if (_deviceBox != null && _deviceBox!.isOpen) {
      // Find device by MQTT ID (deviceId) or UUID
      for (int i = 0; i < _deviceBox!.length; i++) {
        final device = Map<String, dynamic>.from(_deviceBox!.getAt(i) as Map);
        
        // Check both mqttId and id fields
        if (device['mqttId'] == deviceId || device['id'] == deviceId || device['name'] == deviceId) {
          device['sensorStatus'] = sensorStatus;
          _deviceBox!.putAt(i, device);
          debugPrint('✅ DeviceManager: Updated sensorStatus to "$sensorStatus" for device ${device['name']}');
          break;
        }
      }
    }
  }

  void _startPeriodicStatusCheck(String deviceId) {
    _inactivityTimers[deviceId] = Timer.periodic(const Duration(seconds: 30), (timer) {
      final mqttService = _mqttServices[deviceId];
      if (mqttService == null) {
        timer.cancel();
        return;
      }
      
      final isDataReceived = mqttService.isDataReceived(deviceId);
      // Only log when status changes to reduce spam
      if (!isDataReceived) {
        final device = _deviceBox?.get(deviceId);
        if (device != null && device['status'] != 'offline') {
          debugPrint("Device $deviceId went offline - no data received");
          updateDeviceStatus(deviceId, 'offline');
          displayCriticalStatus("no data", deviceId);
          _updateDisconnectionTime(deviceId, DateTime.now(), 'offline');
        }
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

  void updateDeviceCultivationPhase(String deviceId, String phase) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      device['cultivationPhase'] = phase;
      _deviceBox?.put(deviceId, device);
      notifyListeners();
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
    // Use the device name as the MQTT identifier instead of UUID
    // This ensures MQTT topics match the ESP32 device naming
    final deviceMqttId = name.isEmpty ? 'ESP32_${DateTime.now().millisecondsSinceEpoch}' : name;
    final uuid = Uuid();
    final deviceId = uuid.v4(); // Keep UUID for internal storage key
    addDeviceWithId(deviceId, name, deviceMqttId);
  }

  void addDeviceWithId(String deviceId, String name, [String? mqttId]) {
    final deviceMqttId = mqttId ?? name; // Use provided MQTT ID or fallback to name
    final device = {
      'id': deviceId,
      'name': name.isEmpty ? 'Unnamed' : name,
      'mqttId': deviceMqttId, // Store the MQTT identifier
      'status': 'connecting',
      'sensorStatus': '',
      'cultivationPhase': 'Spawn Run', // Default cultivation phase
      'disconnectionTimeResult': 'not connected yet!',
    };
    _deviceBox?.put(deviceId, device);
    notifyListeners();

    // Use MQTT ID for MQTT communication, but keep deviceId for internal management
    _initMqtt(deviceMqttId);

    Timer(Duration(seconds: 5), () {
      if (_deviceBox?.get(deviceId)?['status'] == 'connecting') {
        updateDeviceStatus(deviceId, 'offline');
      }
      if (_deviceBox?.get(deviceId)?['status'] == 'offline') {
        displayCriticalStatus("no data", deviceId);
      }
      _startPeriodicStatusCheck(deviceMqttId);
    });
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