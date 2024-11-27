import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class UserCalendarScreen extends StatefulWidget {
  @override
  _UserCalendarScreenState createState() => _UserCalendarScreenState();
}

class _UserCalendarScreenState extends State<UserCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, String> _scheduledDates = {};
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy', 'es_ES');
  final DateFormat _timeFormatter = DateFormat('hh:mm a', 'es_ES');

  @override
  void initState() {
    super.initState();
    _fetchScheduledDates();
  }

  /// Convertir una fecha de UTC al formato local
  DateTime _convertToLocal(DateTime date) {
    return date.toLocal();
  }

  /// Cargar horarios desde Firestore
  Future<void> _fetchScheduledDates() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('schedule').get();

      Map<DateTime, String> dates = {};
      for (var doc in snapshot.docs) {
        final timestamp = doc['date'] as Timestamp;
        final time = doc['time'] as String;
        dates[_convertToLocal(timestamp.toDate())] = time;
      }

      setState(() {
        _scheduledDates = dates;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las fechas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario (Usuario)'),
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'es_ES',
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            selectedDayPredicate: (day) {
              return _scheduledDates.keys.any((scheduledDate) =>
                  scheduledDate.year == day.year &&
                  scheduledDate.month == day.month &&
                  scheduledDate.day == day.day);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) {
              return _scheduledDates.keys.any((scheduledDate) =>
                      scheduledDate.year == day.year &&
                      scheduledDate.month == day.month &&
                      scheduledDate.day == day.day)
                  ? ['Horario programado']
                  : [];
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _scheduledDates.length,
              itemBuilder: (context, index) {
                DateTime date = _scheduledDates.keys.elementAt(index);
                String time = _scheduledDates[date]!;
                return ListTile(
                  leading: Icon(Icons.event),
                  title: Text(
                    _dateFormatter.format(date),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Horario: $time'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
