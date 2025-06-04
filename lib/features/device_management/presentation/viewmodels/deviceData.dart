import 'package:flutter/material.dart';

class DeviceData with ChangeNotifier {
  double? _temperature;
  double? _humidity;
  int? _lightState;

  double? get temperature => _temperature;
  double? get humidity => _humidity;
  int? get lightState => _lightState;

  // Update data and notify listeners
  void updateData(double? temp, double? hum, int? light) {
    _temperature = temp;
    _humidity = hum;
    _lightState = light;
    notifyListeners();  // Notify listeners of the change
  }
}
