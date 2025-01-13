import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'mqttservice.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Add this package for notifications

class DeviceManager extends ChangeNotifier {
    bool _isDeviceActive = false; // Default device status (inactive)

  Box? _deviceBox;
  final Map<String, MqttService> _mqttServices = {};
  final Map<String, Timer> _inactivityTimers = {};
  final double temperatureThreshold = 32.0;
  final double humidityThreshold = 20.0;
  final int criticalDuration = 10; // In seconds

  DateTime? tempThresholdStartTime;
  DateTime? humidityThresholdStartTime;
  Map<String, dynamic> _sensorData = {};
  Map<String, dynamic> get sensorData => _sensorData;
  bool get isDeviceActive => _isDeviceActive;

  // For notifications
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
/*
  void updateSensorData(String deviceId, double? temperature, double? humidity, int? light) {
    if (!sensorData.containsKey(deviceId)) {
      sensorData[deviceId] = {
        'temperatureHistory': <double>[],
      };
    }

    if (temperature != null) {
      sensorData[deviceId]!['temperatureHistory']!.add(temperature);
    }

    notifyListeners();
  }
  */
  DeviceManager() {
    initHive();
    _initializeNotifications(); // Initialize notifications
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
 bool _isMuted = false;

  bool get isMuted => _isMuted;

  void toggleMute(bool value) {
    _isMuted = value;
    notifyListeners();
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
               // displayCriticalStatus("good", deviceId);

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
       // displayCriticalStatus("good", deviceId);

      },
      onDeviceConnectionStatusChange: (deviceId, status) {
        updateDeviceStatus(deviceId, status);
      },
    );

    _mqttServices[deviceId] = mqttService;
    mqttService.setupMqttClient();
  }

  /// Start periodic status checks for the device
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

  /// Update the status of a device
  void updateDeviceStatus(String deviceId, String newStatus) {
  final device = _deviceBox?.get(deviceId);
  if (device != null) {
    device['status'] = newStatus;
    if (newStatus == 'offline') {
      device['sensorStatus'] = 'no data'; // Set sensor status to "no data" when offline
    }
    _deviceBox?.put(deviceId, device);

    // Update device active status based on new status
    deviceIsActive(deviceId); // This will update _isDeviceActive
  }
}



  /// Mark a device as online
  void _markDeviceOnline(String deviceId) {
    updateDeviceStatus(deviceId, 'online');

  }

/// Check if a device is active
// Update the device status check and notify listeners
bool deviceIsActive(String deviceId) {
  final device = _deviceBox?.get(deviceId);

  if (device != null) {
    final status = device['status'];
    final sensorStatus = device['sensorStatus'];

    // A device is considered active if:
    // - It is online
    // - It has received sensor data (i.e., it's not marked as "no data")
    final isActive = status == 'online' && sensorStatus != 'no data';

    _isDeviceActive = isActive; // Update the _isDeviceActive state
    notifyListeners(); // Notify listeners about the change
    return isActive;
  }

  _isDeviceActive = false; // If device is not found or inactive, mark it as inactive
  notifyListeners();
  return false; 
}


  bool isCritical = false; // Flag to check if the device is in a critical state

void monitorSensors(double? temp, double humidity, String deviceId) {
  final now = DateTime.now();
  bool isTempCritical = false;
  bool isHumidityCritical = false;
  bool isHumNull=false;


  // Check temperature
  if (temp==null){
    displayCriticalStatus("no data in temperture ok?", deviceId);
  }
 else if (temp > temperatureThreshold) {
    tempThresholdStartTime ??= now;
    if (now.difference(tempThresholdStartTime!).inSeconds >= criticalDuration) {
      isTempCritical = true;
    }
  } else {
    tempThresholdStartTime = null; // Reset start time
  }

  // Check humidity
   if (isHumNull==true){
    displayCriticalStatus("no data", deviceId);
  }
  if (humidity < humidityThreshold) {
    humidityThresholdStartTime ??= now;
    if (now.difference(humidityThresholdStartTime!).inSeconds >= criticalDuration) {
      isHumidityCritical = true;
    }
  } else {
    humidityThresholdStartTime = null; // Reset start time
  }

  // If any sensor is critical, update status to "Critical"
  if (isTempCritical || isHumidityCritical) {
    displayCriticalStatus("Critical", deviceId);
  } else {
    // If neither is critical, reset to "good"
    displayCriticalStatus("good", deviceId);
  }
}


  /// Display a critical status for a device
  void displayCriticalStatus(String sensorType, String deviceId) {
  final device = _deviceBox?.get(deviceId);

  if (device != null) {
    if (device['sensorStatus'] != sensorType) {
      // Update the sensorStatus only if it's different
      device['sensorStatus'] = sensorType;
      _deviceBox?.put(deviceId, device); // Save updated device
      print("Sensor status updated to $sensorType for device $deviceId.");

      // Call frequency function if necessary
      frequency(sensorType, deviceId);

      // Notify listeners
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

  // Check if 1 minute has passed since the last notification
  if (now.difference(lastTime).inMinutes < 1) {
    return; // Skip sending notification
  }

  // Update the last notification time
  lastNotificationTime[deviceId] = now;

  // Send the notification
  showNotification(deviceId, "Critical Status: $sensorType");
}

  /// Show a notification
  /// Show a notification with the device name instead of ID
Future<void> showNotification(String deviceId, String message) async {
  // Retrieve device details
  final device = _deviceBox?.get(deviceId);
  final deviceName = device != null && device['name'] != null
      ? device['name']
      : 'Unnamed Device';

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'critical_status_channel',
    'Critical Status Notifications',
    channelDescription: 'Notifications for critical device statuses',
    importance: Importance.low,
    priority: Priority.low,
  );

  const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
  // Show the notification
  if (!isMuted) {
  await flutterLocalNotificationsPlugin.show(
    deviceId.hashCode, // Unique ID for each device notification
    '$deviceName',
    message,
    platformDetails,
    payload: 'device_$deviceId',
  );
  }
  // Save notification to the notifications box
  final notificationsBox = Hive.box('notificationsBox');
  notificationsBox.add({
    'title': 'Device $deviceName',
    'message': message,
    'timestamp': DateTime.now().toString(),
    'id':deviceId,
  });
}

//import 'package:hive/hive.dart';

Future<void> deleteNotificationsByDeviceId(String deviceId) async {
  final notificationsBox = Hive.box('notificationsBox');

  // Find and filter notifications with the matching deviceId
  final notificationsToDelete = notificationsBox.values.toList().where((notification) {
    return notification['id'] == deviceId;
  }).toList();

  if (notificationsToDelete.isNotEmpty) {
    // Loop through all matching notifications and delete them
    for (var notification in notificationsToDelete) {
      final index = notificationsBox.values.toList().indexOf(notification);
      await notificationsBox.deleteAt(index);
    }
    print('All notifications for device $deviceId deleted.');
  } else {
    print('No notifications found for device $deviceId.');
  }
}


  // Add device, remove device, and other methods...


  
  /// Add a new device
  void addDevice(String name) {
    final uuid = Uuid();
   //final deviceId = DateTime.now().toString();

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
       if (_deviceBox?.get(deviceId)?['status'] == 'offline') {
           displayCriticalStatus("no data", deviceId);
          _updateDisconnectionTime(deviceId, DateTime.now(), 'offline');
                  _startPeriodicStatusCheck(deviceId);

      }
    });
  }

  /// Remove a device
  void removeDevice(String deviceId) {
  // Dispose of MQTT services
  _mqttServices[deviceId]?.dispose();
  _mqttServices.remove(deviceId);

  // Cancel and remove the inactivity timer
  _inactivityTimers[deviceId]?.cancel();
  _inactivityTimers.remove(deviceId);

  // Clear the last notification time for the device
  lastNotificationTime.remove(deviceId);

  // Delete the device from Hive
  _deviceBox?.delete(deviceId);

  // Delete notifications associated with the device
  deleteNotificationsByDeviceId(deviceId);

  notifyListeners();
}


  /// Update the name of an existing device
  void updateDeviceName(String deviceId, String newName) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      device['name'] = newName;
      _deviceBox?.put(deviceId, device);
          //showNotification(deviceId, 'Device name updated to $newName');

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