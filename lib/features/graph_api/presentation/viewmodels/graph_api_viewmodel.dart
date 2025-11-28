import 'package:flutter/foundation.dart';
import '../../domain/entities/sensor_graph_data.dart';
import '../../domain/usecases/get_graph_data.dart';

enum GraphApiState { initial, loading, loaded, error }

/// ViewModel for managing graph API data
class GraphApiViewModel extends ChangeNotifier {
  final GetGraphData getGraphDataUseCase;

  GraphApiViewModel({required this.getGraphDataUseCase});

  GraphApiState _state = GraphApiState.initial;
  SensorGraphData? _graphData;
  String _errorMessage = '';
  
  GraphApiState get state => _state;
  SensorGraphData? get graphData => _graphData;
  String get errorMessage => _errorMessage;
  
  bool get isLoading => _state == GraphApiState.loading;
  bool get hasError => _state == GraphApiState.error;
  bool get hasData => _graphData != null && _graphData!.hasData;

  /// Fetch graph data for a controller
  Future<void> fetchGraphData({
    required String controllerId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _state = GraphApiState.loading;
    _errorMessage = '';
    notifyListeners();

    debugPrint('📊 ViewModel: Fetching graph data for controller: $controllerId');
    debugPrint('📊 ViewModel: Time range: $startTime to $endTime');

    final result = await getGraphDataUseCase(
      GetGraphDataParams(
        controllerId: controllerId,
        startTime: startTime,
        endTime: endTime,
      ),
    );

    result.fold(
      (failure) {
        _state = GraphApiState.error;
        _errorMessage = failure.message ?? 'Failed to load graph data';
        _graphData = null;
        debugPrint('❌ ViewModel: Error - $_errorMessage');
        notifyListeners();
      },
      (data) {
        _state = GraphApiState.loaded;
        _graphData = data;
        debugPrint('✅ ViewModel: Graph data loaded successfully');
        debugPrint('📊 Humidity points: ${data.humidity.length}');
        debugPrint('📊 Temperature points: ${data.temperature.length}');
        debugPrint('📊 Water level points: ${data.waterLevel.length}');
        notifyListeners();
      },
    );
  }

  /// Clear current data
  void clearData() {
    _graphData = null;
    _state = GraphApiState.initial;
    _errorMessage = '';
    notifyListeners();
  }
}
