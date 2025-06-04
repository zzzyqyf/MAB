import 'package:hive/hive.dart';
import '../models/device_model.dart';

abstract class DeviceLocalDataSource {
  Future<List<DeviceModel>> getAllDevices();
  Future<DeviceModel> getDeviceById(String id);
  Future<void> addDevice(DeviceModel device);
  Future<void> updateDevice(DeviceModel device);
  Future<void> deleteDevice(String id);
  Future<void> updateDeviceStatus(String id, String status);
  Stream<List<DeviceModel>> watchDevices();
}

class DeviceLocalDataSourceImpl implements DeviceLocalDataSource {
  final Box deviceBox;

  DeviceLocalDataSourceImpl({required this.deviceBox});

  @override
  Future<List<DeviceModel>> getAllDevices() async {
    try {
      final deviceMaps = deviceBox.values.cast<Map<dynamic, dynamic>>().toList();
      return deviceMaps.map((map) => DeviceModel.fromHiveMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get devices from local storage');
    }
  }

  @override
  Future<DeviceModel> getDeviceById(String id) async {
    try {
      final deviceMap = deviceBox.get(id) as Map<dynamic, dynamic>?;
      if (deviceMap == null) {
        throw Exception('Device not found');
      }
      return DeviceModel.fromHiveMap(deviceMap);
    } catch (e) {
      throw Exception('Failed to get device from local storage');
    }
  }

  @override
  Future<void> addDevice(DeviceModel device) async {
    try {
      await deviceBox.put(device.id, device.toHiveMap());
    } catch (e) {
      throw Exception('Failed to add device to local storage');
    }
  }

  @override
  Future<void> updateDevice(DeviceModel device) async {
    try {
      await deviceBox.put(device.id, device.toHiveMap());
    } catch (e) {
      throw Exception('Failed to update device in local storage');
    }
  }

  @override
  Future<void> deleteDevice(String id) async {
    try {
      await deviceBox.delete(id);
    } catch (e) {
      throw Exception('Failed to delete device from local storage');
    }
  }

  @override
  Future<void> updateDeviceStatus(String id, String status) async {
    try {
      final deviceMap = deviceBox.get(id) as Map<dynamic, dynamic>?;
      if (deviceMap != null) {
        final device = DeviceModel.fromHiveMap(deviceMap);
        final updatedDevice = device.copyWith(
          status: status,
          lastUpdated: DateTime.now(),
        );
        await deviceBox.put(id, updatedDevice.toHiveMap());
      }
    } catch (e) {
      throw Exception('Failed to update device status');
    }
  }

  @override
  Stream<List<DeviceModel>> watchDevices() {
    return Stream.periodic(const Duration(seconds: 1), (_) {
      return getAllDevices();
    }).asyncMap((future) => future);
  }
}
