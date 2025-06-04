import 'package:fl_chart/fl_chart.dart';

// Project imports
import '../../features/device_management/presentation/viewmodels/deviceMnanger.dart';

class TemperatureDataService {
  final DeviceManager deviceManager;

  TemperatureDataService(this.deviceManager);

  Future<void> generateTemperatureData(
    String deviceId,
    DateTime currentTime,
    Map<String, dynamic> sensorData,
    List<FlSpot> spots,
    Map<String, DateTime> deviceStartTimes,
    Map<String, bool> deviceStartTimeSet,
  ) async {
    if (sensorData.isEmpty || !deviceManager.deviceIsActive(deviceId)) {
      return;
    }

    deviceStartTimes.putIfAbsent(deviceId, () => currentTime);
    deviceStartTimeSet.putIfAbsent(deviceId, () => false);

    if (!deviceStartTimeSet[deviceId]!) {
      deviceStartTimes[deviceId] = currentTime;
      deviceStartTimeSet[deviceId] = true;
    }

    DateTime deviceStartTime = deviceStartTimes[deviceId]!;

    sensorData.entries
        .where((entry) => entry.key.contains('temperature'))
        .forEach((entry) {
      final temperature = double.tryParse(entry.value.toString()) ?? 0.0;
      final timeElapsed = currentTime.difference(deviceStartTime).inMinutes.toDouble();
      final spot = FlSpot(timeElapsed, temperature);

      spots.add(spot);
    });

    spots.sort((a, b) => a.x.compareTo(b.x));
  }
}
