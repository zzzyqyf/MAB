import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/device.dart';
import '../repositories/device_repository.dart';

class GetAllDevices extends UseCaseWithoutParams<List<Device>> {
  final DeviceRepository repository;

  GetAllDevices(this.repository);

  @override
  Future<Either<Failure, List<Device>>> call() async {
    return await repository.getAllDevices();
  }
}

class GetDeviceById extends UseCase<Device, GetDeviceByIdParams> {
  final DeviceRepository repository;

  GetDeviceById(this.repository);

  @override
  Future<Either<Failure, Device>> call(GetDeviceByIdParams params) async {
    return await repository.getDeviceById(params.id);
  }
}

class AddDevice extends UseCase<void, AddDeviceParams> {
  final DeviceRepository repository;

  AddDevice(this.repository);

  @override
  Future<Either<Failure, void>> call(AddDeviceParams params) async {
    return await repository.addDevice(params.device);
  }
}

class UpdateDevice extends UseCase<void, UpdateDeviceParams> {
  final DeviceRepository repository;

  UpdateDevice(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateDeviceParams params) async {
    return await repository.updateDevice(params.device);
  }
}

class DeleteDevice extends UseCase<void, DeleteDeviceParams> {
  final DeviceRepository repository;

  DeleteDevice(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteDeviceParams params) async {
    return await repository.deleteDevice(params.id);
  }
}

// Parameter classes
class GetDeviceByIdParams {
  final String id;
  GetDeviceByIdParams({required this.id});
}

class AddDeviceParams {
  final Device device;
  AddDeviceParams({required this.device});
}

class UpdateDeviceParams {
  final Device device;
  UpdateDeviceParams({required this.device});
}

class DeleteDeviceParams {
  final String id;
  DeleteDeviceParams({required this.id});
}
