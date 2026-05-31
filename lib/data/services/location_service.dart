import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Kiểm tra và yêu cầu quyền vị trí
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Lấy vị trí hiện tại một lần (với timeout)
  Future<Position> getCurrentLocation() async {
    try {
      bool hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        throw Exception('Vui lòng bật GPS và cấp quyền vị trí');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return position;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream vị trí thời gian thực (đây là cái bạn yêu cầu)
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Cập nhật khi di chuyển >= 50 mét
      ),
    );
  }

  /// Lấy vị trí cuối cùng đã biết
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  /// Kiểm tra GPS có đang bật không
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Kiểm tra quyền hiện tại
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }
}
