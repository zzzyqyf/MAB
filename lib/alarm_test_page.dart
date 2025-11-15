import 'package:flutter/material.dart';
import 'shared/services/alarm_service.dart';

/// Simple test page to test alarm functionality
/// Add this to your app to test the alarm without MQTT
class AlarmTestPage extends StatefulWidget {
  const AlarmTestPage({Key? key}) : super(key: key);

  @override
  State<AlarmTestPage> createState() => _AlarmTestPageState();
}

class _AlarmTestPageState extends State<AlarmTestPage> {
  final AlarmService _alarmService = AlarmService();
  String _status = 'Ready to test alarm';
  int _beepCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Sound Test'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 32),
              
              Text(
                _status,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              if (_alarmService.isAlarmActive)
                Text(
                  'Beeps played: $_beepCount',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              
              const SizedBox(height: 48),
              
              // Start Alarm Button
              if (!_alarmService.isAlarmActive)
                ElevatedButton.icon(
                  onPressed: _startTestAlarm,
                  icon: const Icon(Icons.volume_up, size: 32),
                  label: const Text(
                    'START ALARM TEST',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              
              // Stop Alarm Button
              if (_alarmService.isAlarmActive)
                ElevatedButton.icon(
                  onPressed: _stopTestAlarm,
                  icon: const Icon(Icons.stop, size: 32),
                  label: const Text(
                    'STOP ALARM',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              
              const SizedBox(height: 32),
              
              const Divider(),
              
              const SizedBox(height: 16),
              
              const Text(
                'What should happen:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '🔊 Loud beep every 2 seconds\n'
                '📳 Phone vibration\n'
                '🗣️ Voice announcement\n'
                '✅ Check console logs for details',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'If no sound:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Check phone alarm volume\n'
                '2. Turn off Do Not Disturb\n'
                '3. Check console logs\n'
                '4. You should still feel vibration',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startTestAlarm() async {
    setState(() {
      _status = 'Starting alarm test...';
      _beepCount = 0;
    });

    print('\n\n');
    print('═══════════════════════════════════════');
    print('🧪 ALARM TEST STARTED');
    print('═══════════════════════════════════════');
    print('Time: ${DateTime.now()}');
    print('Device: Running on physical device');
    print('\n');

    await _alarmService.startAlarm('Test Alarm - Temperature Critical: 35.0°C');

    // Count beeps
    setState(() {
      _status = 'Alarm is ACTIVE!\nListen for beeps...';
      _beepCount = 1;
    });

    // Increment beep counter every 2 seconds while alarm is active
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 2));
      if (_alarmService.isAlarmActive && mounted) {
        setState(() {
          _beepCount++;
        });
        return true;
      }
      return false;
    });
  }

  Future<void> _stopTestAlarm() async {
    print('\n');
    print('═══════════════════════════════════════');
    print('🛑 ALARM TEST STOPPED');
    print('═══════════════════════════════════════');
    print('Total beeps: $_beepCount');
    print('Duration: ${_beepCount * 2} seconds');
    print('\n\n');

    await _alarmService.stopAlarm();

    setState(() {
      _status = 'Alarm stopped. Test complete!';
    });

    // Reset after 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _status = 'Ready to test alarm';
        _beepCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _alarmService.stopAlarm();
    super.dispose();
  }
}
