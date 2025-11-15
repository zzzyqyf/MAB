import 'package:flutter/material.dart';

/// Dialog to select snooze duration for alarm notifications
/// 
/// Provides predefined durations from 1 minute to 24 hours
class SnoozePickerDialog extends StatelessWidget {
  const SnoozePickerDialog({Key? key}) : super(key: key);

  static const List<_SnoozeDuration> _durations = [
    _SnoozeDuration(label: '1 minute', duration: Duration(minutes: 1)),
    _SnoozeDuration(label: '5 minutes', duration: Duration(minutes: 5)),
    _SnoozeDuration(label: '15 minutes', duration: Duration(minutes: 15)),
    _SnoozeDuration(label: '30 minutes', duration: Duration(minutes: 30)),
    _SnoozeDuration(label: '1 hour', duration: Duration(hours: 1)),
    _SnoozeDuration(label: '2 hours', duration: Duration(hours: 2)),
    _SnoozeDuration(label: '4 hours', duration: Duration(hours: 4)),
    _SnoozeDuration(label: '8 hours', duration: Duration(hours: 8)),
    _SnoozeDuration(label: '12 hours', duration: Duration(hours: 12)),
    _SnoozeDuration(label: '24 hours', duration: Duration(hours: 24)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.snooze, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Remind me later'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _durations.length,
          itemBuilder: (context, index) {
            final duration = _durations[index];
            
            return ListTile(
              leading: Icon(
                _getIconForDuration(duration.duration),
                color: theme.colorScheme.primary,
              ),
              title: Text(
                duration.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop(duration.duration);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hoverColor: theme.colorScheme.primary.withOpacity(0.1),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  /// Get appropriate icon based on duration
  IconData _getIconForDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return Icons.schedule;
    } else if (duration.inHours < 4) {
      return Icons.access_time;
    } else if (duration.inHours < 12) {
      return Icons.watch_later;
    } else {
      return Icons.bedtime;
    }
  }

  /// Show the snooze picker dialog
  /// Returns selected Duration or null if cancelled
  static Future<Duration?> show(BuildContext context) async {
    return showDialog<Duration>(
      context: context,
      builder: (context) => const SnoozePickerDialog(),
    );
  }
}

/// Internal class to hold duration label and value
class _SnoozeDuration {
  final String label;
  final Duration duration;

  const _SnoozeDuration({
    required this.label,
    required this.duration,
  });
}
