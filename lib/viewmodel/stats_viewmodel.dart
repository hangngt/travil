import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:travil/views/stats/montlystats.dart';

class StatsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  int totalPlanned = 0;
  int totalVisited = 0;

  Map<int, MonthlyStat> monthlyStats = {};

  final List<String> monthNames = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  Future<void> loadStats(String uid) async {
    try {
      isLoading = true;

      notifyListeners();

      monthlyStats = {
        for (int i = 1; i <= 12; i++) i: MonthlyStat(),
      };

      totalPlanned = 0;
      totalVisited = 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('trip_status')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final String status = data['status'] ?? '';

        // PLANNED
        if (status == 'planned' && data['plannedDate'] != null) {
          final plannedDate = (data['plannedDate'] as Timestamp).toDate();

          final month = plannedDate.month;

          monthlyStats[month]!.planned++;

          totalPlanned++;
        }

        // VISITED
        if (status == 'visited' && data['visitedAt'] != null) {
          final visitedDate = (data['visitedAt'] as Timestamp).toDate();

          final month = visitedDate.month;

          monthlyStats[month]!.visited++;

          totalVisited++;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint(
        "loadStats error: $e",
      );
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }
}
