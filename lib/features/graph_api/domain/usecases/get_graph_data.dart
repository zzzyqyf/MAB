import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/sensor_graph_data.dart';
import '../repositories/graph_repository.dart';

/// Use case to get graph data
class GetGraphData implements UseCase<SensorGraphData, GetGraphDataParams> {
  final GraphRepository repository;

  GetGraphData(this.repository);

  @override
  Future<Either<Failure, SensorGraphData>> call(GetGraphDataParams params) async {
    return await repository.getGraphData(
      controllerId: params.controllerId,
      startTime: params.startTime,
      endTime: params.endTime,
    );
  }
}

class GetGraphDataParams {
  final String controllerId;
  final DateTime startTime;
  final DateTime endTime;

  GetGraphDataParams({
    required this.controllerId,
    required this.startTime,
    required this.endTime,
  });
}
