import 'package:flutter/material.dart';
import 'package:travil/viewmodel/calendar_viewmodel.dart';

class NoteCalendar extends StatelessWidget {
  final CalendarViewModel vm;
  final String date;
  const NoteCalendar({super.key, required this.vm, required this.date});
  @override
  Widget build(BuildContext context) {
    // Widget _notes(CalendarViewModel vm, String date) {
    return Expanded(
      flex: 3,
      child: vm.selectedDayNotes.isEmpty
          ? const SizedBox()
          : ListView.builder(
              itemCount: vm.selectedDayNotes.length,
              itemBuilder: (
                context,
                index,
              ) {
                final noteData = vm.selectedDayNotes[index];

                final note = noteData['note'];

                return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TIMELINE
                        SizedBox(
                          width: 30,
                          child: Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 120,
                                color: Colors.grey.shade300,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // CARD
                        _cardnotes(vm, date, noteData, note, context)
                      ],
                    ));
              },
            ),
    );
  }

  Widget _cardnotes(CalendarViewModel vm, String date,
      Map<String, dynamic> noteData, dynamic note, BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.blue.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Activity",
                  ),
                ),
                PopupMenuButton(
                  onSelected: (value) async {
                    if (value == "delete") {
                      await vm.deleteNote(
                        noteData['id'],
                      );
                    }

                    if (value == "edit") {
                      vm.noteController.text = note;

                      showDialog(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            title: const Text(
                              "Edit Timeline",
                            ),
                            content: TextField(
                              controller: vm.noteController,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                  );
                                },
                                child: const Text(
                                  "Cancel",
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  await vm.updateNote(
                                    docId: noteData['id'],
                                    text: vm.noteController.text,
                                  );

                                  Navigator.pop(
                                    context,
                                  );
                                },
                                child: const Text(
                                  "Save",
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: "edit",
                      child: Text("Edit"),
                    ),
                    const PopupMenuItem(
                      value: "delete",
                      child: Text("Delete"),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              note,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Description",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
