import 'package:flutter/material.dart';
import '../services/alarm_service.dart';

/// Dialog for selecting alarm snooze duration
class AlarmSnoozeDialog extends StatelessWidget {
  const AlarmSnoozeDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final snoozeDurations = [
      {'label': '5 minutes', 'duration': const Duration(minutes: 5)},
      {'label': '10 minutes', 'duration': const Duration(minutes: 10)},
      {'label': '15 minutes', 'duration': const Duration(minutes: 15)},
      {'label': '30 minutes', 'duration': const Duration(minutes: 30)},
      {'label': '1 hour', 'duration': const Duration(hours: 1)},
    ];

    return AlertDialog(
      title: const Text('⏰ Snooze Alarm'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How long would you like to snooze the alarm?'),
          const SizedBox(height: 16),
          ...snoozeDurations.map((option) {
            return ListTile(
              title: Text(option['label'] as String),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                Navigator.pop(context);
                await AlarmService().snoozeAlarm(option['duration'] as Duration);
              },
            );
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
