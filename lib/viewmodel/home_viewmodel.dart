import 'package:flutter/material.dart';
import 'package:travil/data/responsive/product_repository.dart';
import '../data/model/product_model.dart';
import '../data/services/location_service.dart';

class HomeViewModel extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();
  final LocationService _locationService = LocationService();

  List<ProductModel> recommendations = [];
  bool isLoading = false;
  String selectedCity = 'Da Nang';

  Future<void> loadRecommendations({bool useGPS = false}) async {
    isLoading = true;
    notifyListeners();

    try {
      if (useGPS) {
        final position = await _locationService.getCurrentLocation();
        recommendations = await _repository.getRecommendations(
          lat: position.latitude,
          lng: position.longitude,
        );
      } else {
        recommendations = await _repository.getRecommendations(
          city: selectedCity,
        );
      }
    } catch (e) {
      print("Error: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  void changeCity(String city) {
    selectedCity = city;
    loadRecommendations();
  }

  Future<void> loadNearbyPlaces() async {
    isLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();

      recommendations = await _repository.getRecommendations(
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      // Hiển thị thông báo lỗi cho người dùng
      print("Lỗi lấy vị trí: $e");
    }

    isLoading = false;
    notifyListeners();
  }
}
