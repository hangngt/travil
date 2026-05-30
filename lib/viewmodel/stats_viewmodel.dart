import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsViewModel extends ChangeNotifier {
  List<FlSpot> travelSpots = [
    const FlSpot(1, 2),
    const FlSpot(2, 5),
    const FlSpot(3, 3),
    const FlSpot(4, 7),
    const FlSpot(5, 4),
    const FlSpot(6, 8),
  ];

  List<String> visitedPlaces = [
    "Ba Na Hills",
    "Hoi An Ancient Town",
    "My Son Sanctuary",
    "Dragon Bridge",
  ];

  void showVisitedPlaces() {
    // Có thể mở dialog hoặc navigate sang màn hình chi tiết
    print("Showing visited places: $visitedPlaces");
  }

  // Có thể thêm hàm load data từ Firestore sau
  Future<void> loadStats() async {
    // TODO: Load real data from Firebase
    notifyListeners();
  }
}
