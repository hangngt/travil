import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      // mở màn hình bật GPS
      await Geolocator.openLocationSettings();

      throw Exception(
        "Vui lòng bật GPS để sử dụng tính năng này",
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        "Bạn chưa cấp quyền vị trí",
      );
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();

      throw Exception(
        "Vui lòng cấp quyền vị trí trong cài đặt",
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
