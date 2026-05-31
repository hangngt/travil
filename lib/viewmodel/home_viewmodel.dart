import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travil/data/responsive/product_repository.dart';
import '../data/model/product_model.dart';
import '../data/services/location_service.dart';

class HomeViewModel extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();
  final LocationService _locationService = LocationService();

  List<ProductModel> recommendations = [];
  bool isLoading = false;
  String selectedCity = 'Da Nang';
  String? errorMessage;

  ///  LOAD RECOMMENDATIONS

  Future<void> loadRecommendations({bool useGPS = false}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (useGPS) {
        final position = await _locationService.getCurrentLocation();

        if (position.latitude == null || position.longitude == null) {
          throw Exception("GPS not ready");
        }

        recommendations = await _repository.getRecommendations(
          city: selectedCity,
          lat: position.latitude,
          lng: position.longitude,
        );
      } else {
        // Chỉ dùng thành phố (không cần GPS)
        recommendations = await _repository.getRecommendations(
          city: selectedCity,
        );
      }
    } catch (e) {
      errorMessage = e.toString();
      print("Error loadRecommendations: $e");
      recommendations = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  ///LOAD NEARBY PLACES (BẮT BUỘC GPS)
  Future<void> loadNearbyPlaces() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();

      if (position.latitude == null || position.longitude == null) {
        throw Exception("Không lấy được GPS");
      }

      recommendations = await _repository.getRecommendations(
        city: selectedCity,
        lat: position.latitude,
        lng: position.longitude,
      );
    } catch (e) {
      errorMessage = e.toString();
      recommendations = [];
      print("Lỗi loadNearbyPlaces: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void changeCity(String city) {
    selectedCity = city;
    loadRecommendations(
        useGPS: false); // Khi đổi thành phố thì không bắt buộc GPS
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
