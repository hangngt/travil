import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:travil/data/model/product_model.dart';
import 'package:travil/data/responsive/product_repository.dart';
import 'package:travil/data/services/location_service.dart';

class MapViewModel extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();

  final LocationService _locationService = LocationService();

  Set<Marker> markers = {};

  LatLng? currentLocation;

  bool isLoading = false;

  List<ProductModel> nearbyPlaces = [];

  Future<void> loadMapData() async {
    isLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();

      currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      nearbyPlaces = await _repository.getRecommendations(
        lat: position.latitude,
        lng: position.longitude,
      );

      _buildMarkers();
    } catch (e) {
      print(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _buildMarkers() {
    markers.clear();

    for (final place in nearbyPlaces) {
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
