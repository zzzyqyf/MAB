import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/sensor_graph_data.dart';
import '../../domain/repositories/graph_repository.dart';
import '../datasources/graph_api_remote_datasource.dart';

/// Implementation of GraphRepository
class GraphRepositoryImpl implements GraphRepository {
  final GraphApiRemoteDataSource remoteDataSource;

  GraphRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SensorGraphData>> getGraphData({
    required String controllerId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final graphDataModel = await remoteDataSource.getGraphData(
        controllerId: controllerId,
        startTime: startTime,
        endTime: endTime,
      );

      // Convert model to entity
      final sensorGraphData = SensorGraphData(
        humidity: graphDataModel.humidity
            .map((point) => DataPoint(value: point.value, time: point.dateTime))
            .toList(),
        temperature: graphDataModel.temperature
            .map((point) => DataPoint(value: point.value, time: point.dateTime))
            .toList(),
        waterLevel: graphDataModel.waterLevel
            .map((point) => DataPoint(value: point.value, time: point.dateTime))
            .toList(),
      );

      return Right(sensorGraphData);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAuthToken() async {
    try {
      await remoteDataSource.clearToken();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
