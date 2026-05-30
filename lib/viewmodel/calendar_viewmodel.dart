import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/model/routine_model.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarViewModel extends ChangeNotifier {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  List<RoutineModel> routines = [];

  final Uuid _uuid = const Uuid();

  // Load routines cho ngày được chọn
  Future<void> loadRoutines(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'routines_${day.toIso8601String().split('T')[0]}';
    final savedRoutines = prefs.getStringList(key) ?? [];

    routines =
        savedRoutines.map((json) {
          final map = Map<String, dynamic>.from(
            jsonDecode(json),
          ); // Cần import dart:convert
          return RoutineModel(
            id: map['id'],
            date: DateTime.parse(map['date']),
            title: map['title'],
            description: map['description'],
            time: map['time'],
          );
        }).toList();

    notifyListeners();
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay = selected;
    focusedDay = focused;
    loadRoutines(selected);
  }

  Future<void> addRoutine(String title, String description, String time) async {
    final routine = RoutineModel(
      id: _uuid.v4(),
      date: selectedDay,
      title: title,
      description: description,
      time: time,
    );

    final prefs = await SharedPreferences.getInstance();
    final key = 'routines_${selectedDay.toIso8601String().split('T')[0]}';

    final saved = prefs.getStringList(key) ?? [];
    saved.add(
      jsonEncode(routine.toJson()),
    ); // Cần thêm method toJson trong RoutineModel

    await prefs.setStringList(key, saved);

    await loadRoutines(selectedDay);
  }

  void showAddRoutineDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String title = '';
        String description = '';
        String time = '09:00';

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Tên hoạt động'),
                onChanged: (val) => title = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Mô tả'),
                onChanged: (val) => description = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Thời gian'),
                onChanged: (val) => time = val,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (title.isNotEmpty) {
                    addRoutine(title, description, time);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Thêm vào lịch'),
              ),
            ],
          ),
        );
      },
    );
  }
}
