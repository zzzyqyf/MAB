import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

// Core
import 'core/constants/app_constants.dart';

// Features - Device Management
import 'features/device_management/data/datasources/device_local_datasource.dart';
import 'features/device_management/data/repositories/device_repository_impl.dart';
import 'features/device_management/domain/repositories/device_repository.dart';
import 'features/device_management/domain/usecases/device_usecases.dart';
import 'features/device_management/presentation/viewmodels/device_view_model.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Device Management
  
  // ViewModels
  sl.registerFactory(
    () => DeviceViewModel(
      getAllDevices: sl(),
      getDeviceById: sl(),
      addDevice: sl(),
      updateDevice: sl(),
      deleteDevice: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllDevices(sl()));
  sl.registerLazySingleton(() => GetDeviceById(sl()));
  sl.registerLazySingleton(() => AddDevice(sl()));
  sl.registerLazySingleton(() => UpdateDevice(sl()));
  sl.registerLazySingleton(() => DeleteDevice(sl()));

  // Repository
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<DeviceLocalDataSource>(
    () => DeviceLocalDataSourceImpl(deviceBox: sl()),
  );

  //! Core
  
  // Hive boxes
  sl.registerLazySingleton<Box>(() => Hive.box(AppConstants.deviceBoxKey));

  //! External
  // You can register external dependencies here
}

Future<void> initializeHive() async {
  await Hive.openBox(AppConstants.deviceBoxKey);
  await Hive.openBox(AppConstants.notificationsBoxKey);
  if (!Hive.isBoxOpen(AppConstants.graphDataBoxKey)) {
    await Hive.openBox(AppConstants.graphDataBoxKey);
  }
}
