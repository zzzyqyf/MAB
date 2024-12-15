import 'package:flutter/foundation.dart';

class SensorDataProvider with ChangeNotifier {
  double? _temperature;
  double? _humidity;
  int? _lightState;

  double? get temperature => _temperature;
  double? get humidity => _humidity;
  int? get lightState => _lightState;

  void updateSensorData(double? temperature, double? humidity, int? lightState) {
    _temperature = temperature;
    _humidity = humidity;
    _lightState = lightState;
    notifyListeners();
  }
}
