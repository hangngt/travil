import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/model/product_model.dart';
import '../data/responsive/product_repository.dart';
import '../data/services/location_service.dart';

class HomeViewModel extends ChangeNotifier {
  final ProductRepository _repository = ProductRepository();
  final LocationService _locationService = LocationService();

  List<ProductModel> recommendations = [];
  List<ProductModel> topRated = [];
  List<ProductModel> nearbyPlaces = [];

  bool isLoading = false;

  String selectedCity = 'Da Nang';
  String? errorMessage;

  // MAP

  LatLng? currentLocation;
  Set<Marker> markers = {};
  ProductModel? selectedPlace;

  // LOAD DATA

  Future<void> loadRecommendations({
    bool useGPS = false,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      if (useGPS) {
        final position = await _locationService.getCurrentLocation();
        currentLocation = LatLng(
          position.latitude,
          position.longitude,
        );

        // recommendations = await _repository.getRecommendations(
        //   city: selectedCity,
        //   lat: position.latitude,
        //   lng: position.longitude,
        // );
        recommendations = await _repository.getRecommendations(
          city: selectedCity,
        ); // test
        print(recommendations.length);
        for (final p in recommendations) {
          print("${p.title} => ${p.lat}, ${p.lng}");
        }
      } else {
        recommendations = await _repository.getRecommendations(
          city: selectedCity,
        );
        print(recommendations.length);
        for (final p in recommendations) {
          print("${p.title} => ${p.lat}, ${p.lng}");
        }
      }

      topRated = [...recommendations];

      topRated.sort(
        (a, b) => b.rating.compareTo(a.rating),
      );

      nearbyPlaces = recommendations;
      _buildMarkers();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNearbyPlaces() async {
    await loadRecommendations(useGPS: true);
  }

  void changeCity(String city) {
    selectedCity = city;
    loadRecommendations();
  }

  // BUILD MARKERS
  void _buildMarkers() {
    markers.clear();
    print("TOTAL MARKERS: ${nearbyPlaces.length}");
    for (final p in nearbyPlaces) {
      print("${p.title} => ${p.lat}, ${p.lng}");
    }
    // PLACES
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
          // icon: BitmapDescriptor.defaultMarkerWithHue(
          //   BitmapDescriptor.hueOrange,
          // ),  //thay màu cho icon gps
          infoWindow: InfoWindow(
            title: place.title,
            snippet: place.location,
          ),
          onTap: () {
            selectedPlace = place;
            notifyListeners();
          },
        ),
      );
    }

    // USER LOCATION

    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("me"),
          position: currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: const InfoWindow(
            title: "You",
          ),
        ),
      );
    }
  }
}
