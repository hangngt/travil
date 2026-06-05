import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/model/product_model.dart';
import '../data/responsive/product_repository.dart';
import '../data/services/product_firestore.dart';

class HomeViewModel extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  final ProductFirestore _firestore = ProductFirestore();

  // PRODUCTS
  List<ProductModel> recommendations = [];
  List<ProductModel> topRated = [];

  // SEARCH
  List<ProductModel> searchResults = [];

  // LOCATION
  List<String> locations = [];
  String? selectedCity;

  // MAP
  Set<Marker> markers = {};
  ProductModel? selectedPlace;

  // STATE
  bool isLoading = false;

  // LOAD INITIAL

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    try {
      locations = await _firestore.getLocations();

      // DEFAULT LOCATION
      if (locations.isNotEmpty && selectedCity == null) {
        selectedCity = locations.first;
      }

      // LOAD PRODUCTS
      if (selectedCity != null) {
        await loadRecommendations();
      }
    } catch (e) {
      debugPrint("LOAD DATA ERROR: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  // LOAD PRODUCTS

  Future<void> loadRecommendations() async {
    if (selectedCity == null) return;

    try {
      recommendations = await _repository.getRecommendations(
        city: selectedCity!,
      );

      // TOP RATED
      topRated = [...recommendations];

      topRated.sort(
        (a, b) => b.rating.compareTo(a.rating),
      );

      _buildMarkers();

      notifyListeners();
    } catch (e) {
      debugPrint("LOAD PRODUCT ERROR: $e");
    }
  }

  // CHANGE CITY

  Future<void> changeCity(String city) async {
    selectedCity = city;

    notifyListeners();

    await loadRecommendations();
  }

  //SEARCH

  Future<void> searchProducts(
    String query,
  ) async {
    if (query.trim().isEmpty) {
      searchResults = [];

      notifyListeners();

      return;
    }

    searchResults = await _firestore.searchProducts(
      query,
    );

    notifyListeners();
  }

  void clearSearch() {
    searchResults.clear();
    notifyListeners();
  }

  //MARKERS

  void _buildMarkers() {
    markers.clear();

    for (final place in recommendations) {
      markers.add(
        Marker(
          markerId: MarkerId(
            place.productId.toString(),
          ),
          position: LatLng(
            place.lat,
            place.lng,
          ),
          infoWindow: InfoWindow(
            title: place.title,
            snippet: place.location,
          ),
        ),
      );
    }
  }
}
