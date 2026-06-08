import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/model/product_model.dart';

class CalendarViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CALENDAR

  DateTime selectedDay = DateTime.now();

  DateTime focusedDay = DateTime.now();

  // CONTROLLER

  final TextEditingController noteController = TextEditingController();

  // DATA

  List<ProductModel> selectedDayTrips = [];

  List<Map<String, dynamic>> selectedDayNotes = [];

  Set<String> tripDays = {};

  bool isLoading = false;

  // DATE KEY
  String getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  // LOAD ALL

  Future<void> loadRoutines(
    DateTime date,
  ) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await Future.wait([
      loadTripsByDate(uid, date),
      loadNotesByDate(uid, date),
    ]);

    notifyListeners();
  }

  // SELECT DAY
  void onDaySelected(
    DateTime selected,
    DateTime focused,
  ) {
    selectedDay = selected;

    focusedDay = focused;

    loadRoutines(selected);

    notifyListeners();
  }

  // LOAD NOTES

  Future<void> loadNotesByDate(
    String uid,
    DateTime date,
  ) async {
    try {
      final start = DateTime(
        date.year,
        date.month,
        date.day,
      );

      final end = start.add(
        const Duration(days: 1),
      );

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('timelines')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where(
            'date',
            isLessThan: Timestamp.fromDate(end),
          )
          .orderBy('date')
          .get();

      selectedDayNotes = snapshot.docs.map((e) {
        return {
          "id": e.id,
          ...e.data(),
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint(
        "loadNotesByDate error: $e",
      );
    }
  }

  // ADD NOTE

  Future<void> addNote(
    String text,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('timelines')
          .add({
        "note": text,
        "date": Timestamp.fromDate(selectedDay),
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await loadNotesByDate(
        uid,
        selectedDay,
      );
    } catch (e) {
      debugPrint("addNote error: $e");
    }
  }

  // UPDATE NOTE

  Future<void> updateNote({
    required String docId,
    required String text,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('timelines')
          .doc(docId)
          .update({
        "note": text,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      await loadNotesByDate(
        uid,
        selectedDay,
      );
    } catch (e) {
      debugPrint(
        "updateNote error: $e",
      );
    }
  }

  // DELETE NOTE

  Future<void> deleteNote(
    String docId,
  ) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('timelines')
          .doc(docId)
          .delete();

      await loadNotesByDate(
        uid,
        selectedDay,
      );
    } catch (e) {
      debugPrint(
        "deleteNote error: $e",
      );
    }
  }

  // DIALOG

  Future<void> showAddRoutineDialog(
    BuildContext context,
  ) async {
    noteController.clear();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "Add Timeline",
          ),
          content: TextField(
            controller: noteController,
            decoration: const InputDecoration(
              hintText: "Enter timeline...",
            ),
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
                final text = noteController.text.trim();

                if (text.isNotEmpty) {
                  await addNote(text);
                }

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

  // LOAD TRIPS

  Future<void> loadTripsByDate(
    String uid,
    DateTime date,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection(
            'trip_status',
          )
          .where(
            'status',
            isEqualTo: 'planned',
          )
          .get();

      selectedDayTrips = snapshot.docs
          .map(
            (e) => ProductModel.fromJson(
              e.data(),
            ),
          )
          .where(
            (p) =>
                p.plannedDate != null &&
                p.plannedDate!.year == date.year &&
                p.plannedDate!.month == date.month &&
                p.plannedDate!.day == date.day,
          )
          .toList();

      tripDays.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (data['plannedDate'] != null) {
          final Timestamp timestamp = data['plannedDate'];

          final planned = timestamp.toDate();

          tripDays.add(
            getDateKey(planned),
          );
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint(
        "loadTripsByDate error: $e",
      );
    }
  }

  // HAS DATA

  bool hasTripOnDay(
    DateTime day,
  ) {
    final key = getDateKey(day);

    return tripDays.contains(key);
  }
}
