import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/model/product_model.dart';
import '../data/services/location_service.dart';
import '../data/services/api_service.dart';

class MapViewModel extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  bool isLoading = false;
  String? errorMessage;

  LatLng? currentLocation;

  List<ProductModel> recommendations = [];
  List<ProductModel> nearbyPlaces = [];

  Set<Marker> markers = {};

  ProductModel? selectedPlace;

  Future<void> loadNearbyPlaces() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      // 1. GPS
      final position = await _locationService.getCurrentLocation();

      currentLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      // 2. API
      final response = await _apiService.getRecommendations(
        city: "Da Nang",
        lat: position.latitude,
        lng: position.longitude,
      );

      final raw = response.map((e) => ProductModel.fromJson(e)).toList();

      debugPrint("RAW: ${raw.length}");

      // 3. SMART SORT (distance + rating)
      recommendations = _smartSort(raw);

      nearbyPlaces = recommendations;

      debugPrint("FINAL: ${nearbyPlaces.length}");

      // 4. MARKERS
      _buildMarkers();
    } catch (e) {
      errorMessage = e.toString();
      debugPrint("ERROR: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // //  SMART SORT: distance + rating
  // List<ProductModel> _smartSort(List<ProductModel> list) {
  //   if (currentLocation == null) return list;

  //   final sorted = [...list];

  //   sorted.sort((a, b) {
  //     final distanceA = Geolocator.distanceBetween(
  //       currentLocation!.latitude,
  //       currentLocation!.longitude,
  //       a.lat,
  //       a.lng,
  //     );

  //     final distanceB = Geolocator.distanceBetween(
  //       currentLocation!.latitude,
  //       currentLocation!.longitude,
  //       b.lat,
  //       b.lng,
  //     );

  //     //  WEIGHTED SCORE
  //     final scoreA = _score(distanceA, a.rating);
  //     final scoreB = _score(distanceB, b.rating);

  //     return scoreA.compareTo(scoreB);
  //   });

  //   final result = <ProductModel>[];
  //   final usedZones = <String>{};

  //   for (final item in sorted) {
  //     final zoneKey = _getZone(item.lat, item.lng);

  //     if (!usedZones.contains(zoneKey) || result.length < 3) {
  //       usedZones.add(zoneKey);
  //       result.add(item);
  //     }

  //     if (result.length >= 10) break;
  //   }

  //   return result;
  // }

  String _getZone(double lat, double lng) {
    // chia vùng ~1km
    final latZone = (lat * 100).round();
    final lngZone = (lng * 100).round();

    return "$latZone-$lngZone";
  }

  List<ProductModel> _smartSort(List<ProductModel> list) {
    if (currentLocation == null) return list;

    final sorted = [...list];

    sorted.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation!.longitude,
        a.lat,
        a.lng,
      );

      final distanceB = Geolocator.distanceBetween(
        currentLocation!.latitude,
        currentLocation!.longitude,
        b.lat,
        b.lng,
      );

      final scoreA = _score(distanceA, a.rating);
      final scoreB = _score(distanceB, b.rating);

      return scoreA.compareTo(scoreB);
    });

    final result = <ProductModel>[];
    final usedZones = <String>{};

    for (final item in sorted) {
      final zoneKey = _getZone(item.lat, item.lng);

      // ưu tiên đa khu vực nhưng KHÔNG chặn dữ liệu
      if (!usedZones.contains(zoneKey) || result.length < 3) {
        usedZones.add(zoneKey);
        result.add(item);
      }

      if (result.length >= 15) break; // tăng từ 10 → 15 cho map
    }

    return result;
  }

  // SCORE FUNCTION (quan trọng nhất)
  double _score(double distance, double rating) {
    // normalize distance (càng gần càng tốt)
    final distanceScore = distance / 1000;

    // rating weight (càng cao càng tốt)
    final ratingScore = (5.0 - rating);

    return distanceScore + ratingScore;
  }

  double distanceFromUser(ProductModel place) {
    if (currentLocation == null) return 0;

    return Geolocator.distanceBetween(
      currentLocation!.latitude,
      currentLocation!.longitude,
      place.lat,
      place.lng,
    );
  }

  void _buildMarkers() {
    markers.clear();

    debugPrint("BUILD MARKERS: ${nearbyPlaces.length}");

    int index = 0;

    for (final place in nearbyPlaces) {
      markers.add(
        Marker(
          markerId: MarkerId("${place.productId}_$index"),
          position: LatLng(
            place.lat,
            place.lng,
          ),
          infoWindow: InfoWindow(
            title: place.title,
            snippet: "⭐ ${place.rating}",
          ),
          onTap: () {
            selectedPlace = place;
            notifyListeners();
          },
        ),
      );

      index++;
    }

    // USER MARKER
    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("me"),
          position: currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(
            title: "You",
          ),
        ),
      );
    }

    debugPrint("FINAL MARKERS: ${markers.length}");
  }
}
