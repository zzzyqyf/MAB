/*
import 'package:flutter/foundation.dart';
import 'package:flutter_application_final/deviceMnanger.dart';

class DeviceIdProvider with ChangeNotifier {
  String _deviceId = '';
  final DeviceManager deviceManager;

  DeviceIdProvider(this.deviceManager);

  String get deviceId => _deviceId;

  Future<void> setDeviceIdFromManager() async {
    // Get the deviceId from DeviceManager
    String? id = await deviceManager.getDeviceId(deviceId);
    setDeviceId(id!);
  }

  void setDeviceId(String id) {
    _deviceId = id;
    notifyListeners();
  }
}
*/