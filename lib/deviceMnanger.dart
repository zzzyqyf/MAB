import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'mqttservice.dart';
import 'package:uuid/uuid.dart';


class DeviceManager extends ChangeNotifier {
  Box? _deviceBox;
  final Map<String, MqttService> _mqttServices = {};
  final Map<String, Timer> _inactivityTimers = {};
  final double temperatureThreshold = 40.0;
  final double humidityThreshold = 20.0;
  final int criticalDuration = 5; // In seconds

  DateTime? tempThresholdStartTime;
  DateTime? humidityThresholdStartTime;
Map<String, dynamic> _sensorData = {};
  Map<String, dynamic> get sensorData => _sensorData;
  DeviceManager() {
    initHive();
  }

  /// Getter to access the raw Hive device box
  Box? get deviceBox => _deviceBox;

  /// Getter to retrieve all devices as a list of maps
  List<Map<String, dynamic>> get devices {
    if (_deviceBox != null && _deviceBox!.isOpen) {
      return _deviceBox!.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Retrieve a device by its ID
  Map<String, dynamic>? getDeviceById(String deviceId) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      return Map<String, dynamic>.from(device);
    }
    return null;
  }

  /// Initialize Hive and load devices
  Future<void> initHive() async {
    await Hive.initFlutter();
    _deviceBox = await Hive.openBox('devices');

    if (_deviceBox != null) {
      for (var device in _deviceBox!.values) {
        final deviceId = device['id'];
        _initMqtt(deviceId);
        _startPeriodicStatusCheck(deviceId);
      }
    }

    notifyListeners();
  }

  /// Initialize an MQTT service for a specific device
  void _initMqtt(String deviceId) {
  print("Initializing MqttService for $deviceId");

  final mqttService = MqttService(
    id: deviceId,
    onDataReceived: (temperature, humidity, lightState) {
      print("Data received: Temp=$temperature, Humidity=$humidity, Light=$lightState");

      _sensorData = {
        'deviceId': deviceId,
        'temperature': temperature,
        'humidity': humidity,
        'lightState': lightState,
      };
      notifyListeners();

      // Update device to 'online' and reset inactivity timer
      _markDeviceOnline(deviceId);
      _updateDisconnectionTime(deviceId, DateTime.now(), 'online');
      monitorSensors(temperature!, humidity!, deviceId);
    },
    onDeviceConnectionStatusChange: (deviceId, status) {
      updateDeviceStatus(deviceId, status);
    },
  );

  _mqttServices[deviceId] = mqttService;
  mqttService.setupMqttClient();
}

  /// Start periodic status checks for the device
  void _startPeriodicStatusCheck(String deviceId ) {
    _inactivityTimers[deviceId] = Timer.periodic(const Duration(seconds: 5), (timer) {
      final mqttService = _mqttServices[deviceId];
      if (mqttService == null) {
        timer.cancel();
        return;
      }

      final isDataReceived = mqttService.isDataReceived(deviceId);
      if (!isDataReceived) {
        updateDeviceStatus(deviceId, 'offline');
         displayCriticalStatus("no data",deviceId);
_updateDisconnectionTime(deviceId, DateTime.now(), 'offline');

      }

       // displayCriticalStatus("Critical");

    });
  }

  /// Update the status of a device
  void updateDeviceStatus(String deviceId, String newStatus) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      device['status'] = newStatus;
      _deviceBox?.put(deviceId, device);
      notifyListeners();
    }
  }
void updateSensorData(Map<String, dynamic> newData) {
    _sensorData = newData;
    notifyListeners();
  }
  /// Mark a device as online
  void _markDeviceOnline(String deviceId) {
    updateDeviceStatus(deviceId, 'online');

  }
void monitorSensors( temp,  humidity,String deviceId) {
    final now = DateTime.now();

    // Check temperature
    if (temp > temperatureThreshold) {
      tempThresholdStartTime ??= now; // Set start time if not already set
      if (now.difference(tempThresholdStartTime!).inSeconds >= criticalDuration) {
        displayCriticalStatus("Critical ",deviceId);
      }
    } else {
      tempThresholdStartTime = null;
              displayCriticalStatus("good",deviceId);
 // Reset if within safe range
    }

    // Check humidity
    if (humidity < humidityThreshold) {
      humidityThresholdStartTime ??= now;
      if (now.difference(humidityThresholdStartTime!).inSeconds >= criticalDuration) {
        displayCriticalStatus("Critical",deviceId);
      }
    } else {
      humidityThresholdStartTime = null;
              displayCriticalStatus("good", deviceId);

    }
  }
  void displayCriticalStatus(String sensorType,String deviceId) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      device['sensorStatus'] = sensorType;
      _deviceBox?.put(deviceId, device);
      notifyListeners();
    }
    print("$sensorType has been in the threshold for $criticalDuration seconds!,");
    // Update your UI or notification here
  }
  /// Add a new device
  void addDevice(String name) {
    final uuid = Uuid();
   // final deviceId = DateTime.now().toString();

final deviceId = uuid.v4();  // Generates a random UUID
    final device = {
      'id': deviceId,
      'name': name.isEmpty ? 'Unnamed Device' : name,
      'status': 'connecting',
      'sensorStatus':'no data',
      'disconnectionTimeResult':'not connected yet!',
    };
    _deviceBox?.put(deviceId, device);
    notifyListeners();

    _initMqtt(deviceId);

    Timer(Duration(seconds: 5), () {
      
      if (_deviceBox?.get(deviceId)?['status'] == 'connecting') {
        updateDeviceStatus(deviceId, 'offline');
        _startPeriodicStatusCheck(deviceId);
      }
       if (_deviceBox?.get(deviceId)?['sensorStatus'] == 'no data') {
           displayCriticalStatus("no data", deviceId);
          _updateDisconnectionTime(deviceId, DateTime.now(), 'offline');
                  _startPeriodicStatusCheck(deviceId);

      }
    });
  }

  /// Remove a device
  void removeDevice(String deviceId) {
    _mqttServices[deviceId]?.dispose();
    _mqttServices.remove(deviceId);
    _inactivityTimers[deviceId]?.cancel();
    _inactivityTimers.remove(deviceId);

    _deviceBox?.delete(deviceId);
    notifyListeners();
  }

  /// Update the name of an existing device
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

    // Explicitly cast the device to Map<String, dynamic> if it is a Map<dynamic, dynamic>
    return device is Map<String, dynamic> ? device : null; // If it's not Map<String, dynamic>, return null
  }
  // Update disconnection time for a device
void _updateDisconnectionTime(String deviceId, DateTime timestamp, String newStatus) {
  final device = _deviceBox?.get(deviceId);
  if (device != null) {
    if (newStatus == 'offline' && device['disconnectionTimeResult'] != 'offline') {
      // Set the disconnection time only when transitioning to "offline"
      device['disconnectionTimestamp'] = timestamp.toLocal().toString(); // Store the timestamp
      device['disconnectionTimeResult'] = 'offline';
      print("$deviceId was disconnected at: ${device['disconnectionTimestamp']}");
    } else if (newStatus == 'online') {
      // Update status to "connected" without altering disconnection timestamp
      device['disconnectionTimeResult'] = 'online';
      print("$deviceId is now connected.");
    }

    // Save the updated device state
    _deviceBox?.put(deviceId, device);
    notifyListeners();
  }
}




// Retrieve the disconnection time or connection status
String getDisconnectionTime(String deviceId) {
  final device = _deviceBox?.get(deviceId);
  if (device != null) {
    final result = device['disconnectionTimeResult'] ?? 'online';
    if (result == 'online') {
      return 'Connected'; // Device is currently connected
    }
    final timestamp = device['disconnectionTimestamp'] ?? 'N/A';
    return "Disconnected at $timestamp"; // Display the fixed disconnection time
  }
  return 'No data available'; // Default if no device found
}




// Initialize devices on app startup
void initializeDevices() {
  if (_deviceBox != null) {
    _deviceBox?.toMap().forEach((deviceId, deviceData) {
      final status = deviceData['disconnectionTimeResult'] ?? 'connected';
    final timestamp = deviceData['disconnectionTimestamp'] ?? 'N/A';
     print("Device $deviceId is $status. Last disconnected at: $timestamp");
      // You can add further initialization logic here
    });
  }
}
}