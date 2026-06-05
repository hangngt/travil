import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:travil/widget/note_calendar.dart';

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
    DateTime now = DateTime.now();

    String date = "${now.day}/${now.month}/${now.year}";

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          vm.showAddRoutineDialog(
            context,
          );
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar(
              focusedDay: vm.focusedDay,
              firstDay: DateTime(2024),
              lastDay: DateTime(2030),
              selectedDayPredicate: (
                day,
              ) {
                return isSameDay(
                  vm.selectedDay,
                  day,
                );
              },
              onDaySelected: vm.onDaySelected,
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (
                  context,
                  day,
                  focusedDay,
                ) {
                  final hasData = vm.hasTripOnDay(
                    day,
                  );

                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: hasData ? Colors.orange.shade100 : null,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${day.day}",
                        style: TextStyle(
                          fontWeight:
                              hasData ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // PLANNED TRIPS
            Expanded(
              flex: 2,
              child: vm.selectedDayTrips.isEmpty
                  ? const Center(
                      child: Text(
                        "No planned trips",
                      ),
                    )
                  : ListView.builder(
                      itemCount: vm.selectedDayTrips.length,
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final trip = vm.selectedDayTrips[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                8,
                              ),
                              child: Image.network(
                                trip.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              trip.title,
                            ),
                            subtitle: Text(
                              trip.location,
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // NOTES
            NoteCalendar(
              vm: vm,
              date: date,
            )
          ],
        ),
      ),
    );
  }
}
