import 'package:flutter/material.dart';
import '../../../shared/utils/DateSelectionPage.dart';
import '../../../shared/services/TextToSpeech.dart';

/// Reusable historical data button component for graph screens
/// Provides consistent styling and functionality for loading historical data
class HistoricalDataButton extends StatelessWidget {
  final Function(DateTime, String) onDateSelected;
  final String deviceId;

  const HistoricalDataButton({
    super.key,
    required this.onDateSelected,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.history, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DateSelectionPage(
                    onDateSelected: (selectedDate) {
                      onDateSelected(selectedDate, deviceId);
                      TextToSpeech.speak(
                        "Selected date: ${selectedDate.month}-${selectedDate.day}-${selectedDate.year}",
                      );
                    },
                  ),
                ),
              );
            },
            label: const Text(
              "Load Historical Cycles for Date",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
