import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Widget for selecting a date from a calendar
class DateSelectorWidget extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const DateSelectorWidget({
    Key? key,
    required this.initialDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  State<DateSelectorWidget> createState() => _DateSelectorWidgetState();
}

class _DateSelectorWidgetState extends State<DateSelectorWidget> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _focusedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
        daysOfWeekHeight: 40,
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
          weekendStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
            return Center(
              child: Text(
                days[day.weekday % 7],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now(),
        focusedDay: _focusedDate,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDate, selectedDay)) {
            setState(() {
              _selectedDate = selectedDay;
              _focusedDate = focusedDay;
            });
            widget.onDateSelected(selectedDay);
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDate = focusedDay;
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }
}
