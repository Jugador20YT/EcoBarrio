import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AdminCalendarScreen extends StatefulWidget {
  @override
  _AdminCalendarScreenState createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, Map<String, dynamic>> _scheduledDates =
      {}; // Incluye info de cada horario
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy', 'es_ES');
  final DateFormat _timeFormatter = DateFormat('hh:mm a', 'es_ES');

  @override
  void initState() {
    super.initState();
    _fetchScheduledDates();
  }

  /// Convertir una fecha local al formato UTC
  DateTime _convertToUTC(DateTime date) {
    return DateTime.utc(
        date.year, date.month, date.day, date.hour, date.minute);
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

      Map<DateTime, Map<String, dynamic>> dates = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['date'] as Timestamp;
        final time = data['time'] as String;
        final addedBy = data['addedByUid'] as String;

        dates[_convertToLocal(timestamp.toDate())] = {
          'time': time,
          'addedByUid': addedBy,
          'docId': doc.id, // Para identificar el documento en Firestore
        };
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

  /// Seleccionar un día y programar o eliminar horario
  Future<void> _selectTimeAndSchedule(DateTime date) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Si ya existe un horario para esta fecha, eliminarlo
    if (_scheduledDates.containsKey(date)) {
      final addedByUid = _scheduledDates[date]!['addedByUid'];

      if (addedByUid != currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'No puedes eliminar horarios creados por otro administrador.')),
        );
        return;
      }

      try {
        final docId = _scheduledDates[date]!['docId'];
        await FirebaseFirestore.instance
            .collection('schedule')
            .doc(docId)
            .delete();

        setState(() {
          _scheduledDates.remove(date);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Horario eliminado para ${_dateFormatter.format(date)}')),
        );
        return;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el horario: $e')),
        );
        return;
      }
    }

    // Si no hay horario, abrir selector de hora
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      String formattedTime = pickedTime.format(context);

      DateTime dateTimeWithTime = DateTime(
        date.year,
        date.month,
        date.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      try {
        final docRef =
            await FirebaseFirestore.instance.collection('schedule').add({
          'date': _convertToUTC(dateTimeWithTime),
          'time': formattedTime,
          'addedByUid': currentUser.uid,
          'addedByEmail':
              currentUser.email, // Información adicional para mostrar
        });

        setState(() {
          _scheduledDates[date] = {
            'time': formattedTime,
            'addedByUid': currentUser.uid,
            'docId': docRef.id,
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Horario asignado: $formattedTime')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar el horario: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario (Administrador)'),
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

              _selectTimeAndSchedule(selectedDay);
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
                String time = _scheduledDates[date]!['time'];
                String addedByUid = _scheduledDates[date]!['addedByUid'];

                return ListTile(
                  leading: Icon(Icons.event),
                  title: Text(
                    _dateFormatter.format(date),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Horario: $time\nUID: $addedByUid'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
