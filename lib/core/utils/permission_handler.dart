import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionHandler {
  static Future<geo.LocationPermission> checkLocationPermission() async {
    return await geo.Geolocator.checkPermission();
  }

  static Future<geo.LocationPermission> requestLocationPermission() async {
    geo.LocationPermission permission = await geo.Geolocator.requestPermission();
    return permission;
  }

  static Future<bool> isLocationPermissionPermanentlyDenied() async {
    final permission = await geo.Geolocator.checkPermission();
    return permission == geo.LocationPermission.deniedForever;
  }

  static Future<void> openSettings() async {
    await ph.openAppSettings();
  }

  static Future<bool> checkCameraPermission() async {
    return await ph.Permission.camera.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await ph.Permission.camera.request();
    return status.isGranted;
  }
}
