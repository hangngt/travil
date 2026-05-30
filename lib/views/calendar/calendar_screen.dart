import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:travil/widget/routine_timeline.dart';
import '../../viewmodel/calendar_viewmodel.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<CalendarViewModel>().loadRoutines(DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => vm.showAddRoutineDialog(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar(
              focusedDay: vm.focusedDay,
              firstDay: DateTime(2024),
              lastDay: DateTime(2027),
              selectedDayPredicate: (day) => isSameDay(vm.selectedDay, day),
              onDaySelected: vm.onDaySelected,
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  vm.routines.isEmpty
                      ? const Center(
                        child: Text("Không có lịch trình nào trong ngày này"),
                      )
                      : ListView.builder(
                        itemCount: vm.routines.length,
                        itemBuilder: (context, index) {
                          return RoutineTimeline(routine: vm.routines[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
