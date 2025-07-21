import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Project imports
import '../../presentation/viewmodels/deviceManager.dart';

class SensorDataWidget extends StatelessWidget {
  const SensorDataWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceManager>(
      builder: (context, deviceManager, child) {
        final sensorData = deviceManager.sensorData;

        if (sensorData.isEmpty) {
          return const Text('No sensor data available.');
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Device ID: ${sensorData['deviceId']}'),
            Text('Temperature: ${sensorData['temperature']}°C'),
            Text('Humidity: ${sensorData['humidity']}%'),
            Text('Light: ${sensorData['lightState']}'),
          ],
        );
      },
    );
  }
}
