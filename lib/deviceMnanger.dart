import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'mqttservice.dart';

class DeviceManager extends ChangeNotifier {
  Box? _deviceBox;
  final Map<String, MqttService> _mqttServices = {};
  final Map<String, Timer> _inactivityTimers = {};

  DeviceManager() {
    _initHive();
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
  Future<void> _initHive() async {
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
        _markDeviceOnline(deviceId);
      },
      onDeviceConnectionStatusChange: (deviceId, status) {
        _updateDeviceStatus(deviceId, status);
      },
    );

    _mqttServices[deviceId] = mqttService;
    mqttService.setupMqttClient();
  }

  /// Start periodic status checks for the device
  void _startPeriodicStatusCheck(String deviceId) {
    _inactivityTimers[deviceId] = Timer.periodic(Duration(seconds: 10), (timer) {
      final mqttService = _mqttServices[deviceId];
      if (mqttService == null) {
        timer.cancel();
        return;
      }

      final isDataReceived = mqttService.isDataReceived(deviceId);
      if (!isDataReceived) {
        _updateDeviceStatus(deviceId, 'offline');
      }
    });
  }

  /// Update the status of a device
  void _updateDeviceStatus(String deviceId, String newStatus) {
    final device = _deviceBox?.get(deviceId);
    if (device != null) {
      device['status'] = newStatus;
      _deviceBox?.put(deviceId, device);
      notifyListeners();
    }
  }

  /// Mark a device as online
  void _markDeviceOnline(String deviceId) {
    _updateDeviceStatus(deviceId, 'online');
  }

  /// Add a new device
  void addDevice(String name) {
    final deviceId = DateTime.now().toString();
    final device = {
      'id': deviceId,
      'name': name.isEmpty ? 'Unnamed Device' : name,
      'status': 'connecting',
    };
    _deviceBox?.put(deviceId, device);
    notifyListeners();

    _initMqtt(deviceId);

    Timer(Duration(seconds: 10), () {
      if (_deviceBox?.get(deviceId)?['status'] == 'connecting') {
        _updateDeviceStatus(deviceId, 'offline');
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
}
