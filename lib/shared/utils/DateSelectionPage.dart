import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// Project imports
import '../services/TextToSpeech.dart';

class DateSelectionPage extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const DateSelectionPage({required this.onDateSelected, Key? key}) : super(key: key);

  @override
  _DateSelectionPageState createState() => _DateSelectionPageState();
}

class _DateSelectionPageState extends State<DateSelectionPage> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 6, 94, 135),
              Color.fromARGB(255, 84, 90, 95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  "Select a Date",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime.now(),
                    focusedDay: _focusedDate,
                    selectedDayPredicate: (day) => _selectedDate == day,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                        _focusedDate = focusedDay;

                        // Announce the selected date
                        TextToSpeech.speak(
                          "You selected ${selectedDay.month}-${selectedDay.day}-${selectedDay.year}",
                        );
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Color.fromARGB(255, 6, 94, 135),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color.fromARGB(255, 84, 90, 95),
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      weekendTextStyle: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                      outsideDaysVisible: false,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        color: Color.fromARGB(255, 6, 94, 135),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Color.fromARGB(255, 6, 94, 135),
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Color.fromARGB(255, 6, 94, 135),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: const Color.fromARGB(255, 6, 94, 135),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (_selectedDate != null) {
                    widget.onDateSelected(_selectedDate!);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please select a date first.",
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  "Confirm Date",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
