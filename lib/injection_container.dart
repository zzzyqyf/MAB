import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// Core
import 'core/constants/app_constants.dart';

// Features - Device Management
import 'features/device_management/data/datasources/device_local_datasource.dart';
import 'features/device_management/data/repositories/device_repository_impl.dart';
import 'features/device_management/domain/repositories/device_repository.dart';
import 'features/device_management/domain/usecases/device_usecases.dart';
import 'features/device_management/presentation/viewmodels/device_view_model.dart';

// Features - Graph API
import 'features/graph_api/data/datasources/graph_api_remote_datasource.dart';
import 'features/graph_api/data/repositories/graph_repository_impl.dart';
import 'features/graph_api/domain/repositories/graph_repository.dart';
import 'features/graph_api/domain/usecases/get_graph_data.dart';
import 'features/graph_api/presentation/viewmodels/graph_api_viewmodel.dart';

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

  //! Features - Graph API
  
  // ViewModels
  sl.registerFactory(
    () => GraphApiViewModel(getGraphDataUseCase: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetGraphData(sl()));

  // Repository
  sl.registerLazySingleton<GraphRepository>(
    () => GraphRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<GraphApiRemoteDataSource>(
    () => GraphApiRemoteDataSource(client: sl()),
  );

  //! Core
  
  // Hive boxes
  sl.registerLazySingleton<Box>(() => Hive.box(AppConstants.deviceBoxKey));

  //! External
  // HTTP Client with SSL bypass for Android compatibility
  sl.registerLazySingleton<http.Client>(() {
    // Create SecurityContext that allows any certificate
    final context = SecurityContext(withTrustedRoots: false);
    
    try {
      // Create a new HttpClient with custom context
      final secureClient = HttpClient(context: context);
      secureClient.badCertificateCallback = (cert, host, port) {
        print('⚠️ Bypassing certificate check for $host:$port');
        return true;
      };
      secureClient.connectionTimeout = const Duration(seconds: 30);
      secureClient.idleTimeout = const Duration(seconds: 30);
      
      print('✅ Custom HttpClient with SecurityContext created');
      return IOClient(secureClient);
    } catch (e) {
      print('⚠️ Fallback to default HttpClient: $e');
      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (cert, host, port) => true;
      httpClient.connectionTimeout = const Duration(seconds: 30);
      httpClient.idleTimeout = const Duration(seconds: 30);
      return IOClient(httpClient);
    }
  });
}

Future<void> initializeHive() async {
  await Hive.openBox(AppConstants.deviceBoxKey);
  await Hive.openBox(AppConstants.notificationsBoxKey);
  if (!Hive.isBoxOpen(AppConstants.graphDataBoxKey)) {
    await Hive.openBox(AppConstants.graphDataBoxKey);
  }
  
  // Initialize Graph API data source (for token caching)
  final graphApiDataSource = sl<GraphApiRemoteDataSource>();
  await graphApiDataSource.initialize();
}
