import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/TextToSpeech.dart';

/// Reusable time range navigation component for graph screens
/// Provides consistent styling and functionality for time navigation
class TimeRangeNavigator extends StatelessWidget {
  final double minX;
  final double maxX;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final DateTime? cycleStartTime;

  const TimeRangeNavigator({
    super.key,
    required this.minX,
    required this.maxX,
    required this.onPrevious,
    required this.onNext,
    this.cycleStartTime,
  });

  void _announceRange() {
    if (cycleStartTime != null) {
      DateTime startTime = cycleStartTime!.add(Duration(minutes: minX.toInt()));
      DateTime endTime = cycleStartTime!.add(Duration(minutes: maxX.toInt()));

      String announcement = "You are now exploring data from ${DateFormat('hh:mm a').format(startTime)} to ${DateFormat('hh:mm a').format(endTime)}.";
      TextToSpeech.speak(announcement);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              onPrevious();
              _announceRange();
            },
          ),
          Text(
            'Scroll Time Range: ${maxX.toInt()} minutes',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              onNext();
              _announceRange();
            },
          ),
        ],
      ),
    );
  }
}
