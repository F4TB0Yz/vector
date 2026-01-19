import 'package:geolocator/geolocator.dart' as geo;

class PermissionHandler {
  static Future<geo.LocationPermission> checkLocationPermission() async {
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        // El usuario negó el permiso temporalmente.
        // La UI puede mostrar un mensaje y volver a preguntar.
        return geo.LocationPermission.denied;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      // El usuario negó el permiso permanentemente.
      // La UI debe guiar al usuario a la configuración de la app.
      return geo.LocationPermission.deniedForever;
    }

    // Permiso concedido (whileInUse o always)
    return permission;
  }

  // Se podrían agregar otros handlers de permisos aquí (cámara, notificaciones, etc.)
}
