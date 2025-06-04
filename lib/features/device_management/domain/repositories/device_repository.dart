import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/device.dart';

abstract class DeviceRepository {
  Future<Either<Failure, List<Device>>> getAllDevices();
  Future<Either<Failure, Device>> getDeviceById(String id);
  Future<Either<Failure, void>> addDevice(Device device);
  Future<Either<Failure, void>> updateDevice(Device device);
  Future<Either<Failure, void>> deleteDevice(String id);
  Future<Either<Failure, void>> updateDeviceStatus(String id, String status);
  Stream<List<Device>> watchDevices();
}
