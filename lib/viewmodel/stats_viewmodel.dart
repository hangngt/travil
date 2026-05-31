import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsViewModel extends ChangeNotifier {
  List<FlSpot> travelSpots = [
    const FlSpot(1, 3),
    const FlSpot(2, 5),
    const FlSpot(3, 2),
    const FlSpot(4, 7),
    const FlSpot(5, 4),
    const FlSpot(6, 8),
  ];

  List<String> visitedPlaces = [
    "Ba Na Hills",
    "Hoi An Ancient Town",
    "Dragon Bridge",
    "My Son Sanctuary",
  ];

  int totalTrips = 12;
  int totalDays = 45;

  void loadStats() {
    notifyListeners();
  }

  void showVisitedPlaces() {
    // Có thể mở bottom sheet hoặc navigate
    print("Visited Places: $visitedPlaces");
  }
}
