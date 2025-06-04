import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/device_repository.dart';
import '../models/device_model.dart';
import '../datasources/device_local_datasource.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceLocalDataSource localDataSource;

  DeviceRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Device>>> getAllDevices() async {
    try {
      final devices = await localDataSource.getAllDevices();
      return Right(devices);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Device>> getDeviceById(String id) async {
    try {
      final device = await localDataSource.getDeviceById(id);
      return Right(device);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addDevice(Device device) async {
    try {
      final deviceModel = DeviceModel(
        id: device.id,
        name: device.name,
        status: device.status,
        sensorStatus: device.sensorStatus,
        lastUpdated: device.lastUpdated,
        sensorData: device.sensorData,
      );
      await localDataSource.addDevice(deviceModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateDevice(Device device) async {
    try {
      final deviceModel = DeviceModel(
        id: device.id,
        name: device.name,
        status: device.status,
        sensorStatus: device.sensorStatus,
        lastUpdated: device.lastUpdated,
        sensorData: device.sensorData,
      );
      await localDataSource.updateDevice(deviceModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteDevice(String id) async {
    try {
      await localDataSource.deleteDevice(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateDeviceStatus(String id, String status) async {
    try {
      await localDataSource.updateDeviceStatus(id, status);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Stream<List<Device>> watchDevices() {
    return localDataSource.watchDevices();
  }
}
