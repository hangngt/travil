import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationService {
  /// Kiểm tra và yêu cầu quyền vị trí
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // GPS chưa bật
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false; // Người dùng từ chối
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false; // Người dùng chặn vĩnh viễn
    }

    return true;
  }

  /// Lấy vị trí hiện tại
  Future<Position> getCurrentLocation() async {
    try {
      bool hasPermission = await _handleLocationPermission();

      if (!hasPermission) {
        throw Exception('Vui lòng bật GPS và cấp quyền vị trí');
      }

      // Lấy vị trí với độ chính xác cao
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      rethrow; // Để ViewModel xử lý lỗi
    }
  }

  /// Lấy vị trí cuối cùng (nếu có)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Kiểm tra xem có quyền vị trí không
  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}
