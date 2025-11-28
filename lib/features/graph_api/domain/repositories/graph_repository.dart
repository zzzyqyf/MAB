import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/sensor_graph_data.dart';

/// Abstract repository for graph data
abstract class GraphRepository {
  /// Fetch graph data for a controller within a time range
  Future<Either<Failure, SensorGraphData>> getGraphData({
    required String controllerId,
    required DateTime startTime,
    required DateTime endTime,
  });

  /// Clear cached authentication token
  Future<Either<Failure, void>> clearAuthToken();
}
