import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/device.dart';
import '../../domain/usecases/device_usecases.dart';

enum DeviceViewState { initial, loading, loaded, error }

class DeviceViewModel extends ChangeNotifier {
  final GetAllDevices _getAllDevices;
  final GetDeviceById _getDeviceById;
  final AddDevice _addDevice;
  final UpdateDevice _updateDevice;
  final DeleteDevice _deleteDevice;

  DeviceViewModel({
    required GetAllDevices getAllDevices,
    required GetDeviceById getDeviceById,
    required AddDevice addDevice,
    required UpdateDevice updateDevice,
    required DeleteDevice deleteDevice,
  })  : _getAllDevices = getAllDevices,
        _getDeviceById = getDeviceById,
        _addDevice = addDevice,
        _updateDevice = updateDevice,
        _deleteDevice = deleteDevice;

  DeviceViewState _state = DeviceViewState.initial;
  List<Device> _devices = [];
  Device? _selectedDevice;
  String _errorMessage = '';

  // Getters
  DeviceViewState get state => _state;
  List<Device> get devices => _devices;
  Device? get selectedDevice => _selectedDevice;
  String get errorMessage => _errorMessage;
  bool get isLoading => _state == DeviceViewState.loading;
  bool get hasError => _state == DeviceViewState.error;

  void _setState(DeviceViewState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(DeviceViewState.error);
  }

  Future<void> loadDevices() async {
    _setState(DeviceViewState.loading);
    
    final result = await _getAllDevices();
    
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (devices) {
        _devices = devices;
        _setState(DeviceViewState.loaded);
      },
    );
  }

  Future<void> loadDeviceById(String id) async {
    _setState(DeviceViewState.loading);
    
    final result = await _getDeviceById(GetDeviceByIdParams(id: id));
    
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (device) {
        _selectedDevice = device;
        _setState(DeviceViewState.loaded);
      },
    );
  }

  Future<bool> addNewDevice(Device device) async {
    _setState(DeviceViewState.loading);
    
    final result = await _addDevice(AddDeviceParams(device: device));
    
    return result.fold(
      (failure) {
        _setError(_mapFailureToMessage(failure));
        return false;
      },
      (_) {
        _devices.add(device);
        _setState(DeviceViewState.loaded);
        return true;
      },
    );
  }

  Future<bool> updateExistingDevice(Device device) async {
    _setState(DeviceViewState.loading);
    
    final result = await _updateDevice(UpdateDeviceParams(device: device));
    
    return result.fold(
      (failure) {
        _setError(_mapFailureToMessage(failure));
        return false;
      },
      (_) {
        final index = _devices.indexWhere((d) => d.id == device.id);
        if (index != -1) {
          _devices[index] = device;
        }
        _setState(DeviceViewState.loaded);
        return true;
      },
    );
  }

  Future<bool> removeDevice(String id) async {
    _setState(DeviceViewState.loading);
    
    final result = await _deleteDevice(DeleteDeviceParams(id: id));
    
    return result.fold(
      (failure) {
        _setError(_mapFailureToMessage(failure));
        return false;
      },
      (_) {
        _devices.removeWhere((device) => device.id == id);
        _setState(DeviceViewState.loaded);
        return true;
      },
    );
  }

  void clearError() {
    _errorMessage = '';
    if (_state == DeviceViewState.error) {
      _setState(DeviceViewState.loaded);
    }
  }

  void setSelectedDevice(Device? device) {
    _selectedDevice = device;
    notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Failure';
      case CacheFailure:
        return 'Cache Failure';
      case NetworkFailure:
        return 'Network Failure';
      case ValidationFailure:
        return (failure as ValidationFailure).message;
      default:
        return 'Unexpected Error';
    }
  }
}
