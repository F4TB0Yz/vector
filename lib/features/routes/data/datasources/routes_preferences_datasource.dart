import 'package:shared_preferences/shared_preferences.dart';

/// DataSource para persistir la selección de rutas y preferencias locales.
class RoutesPreferencesDataSource {
  final SharedPreferences _prefs;

  static const String _keySelectedRouteId = 'selected_route_id';
  static const String _keySelectedRouteDate = 'selected_route_date';

  RoutesPreferencesDataSource(this._prefs);

  /// Guarda el ID de la ruta seleccionada y la fecha de selección.
  Future<void> saveSelectedRoute(String routeId, DateTime date) async {
    await _prefs.setString(_keySelectedRouteId, routeId);
    await _prefs.setString(_keySelectedRouteDate, date.toIso8601String());
  }

  /// Obtiene el ID de la ruta guardada.
  String? getSelectedRouteId() {
    return _prefs.getString(_keySelectedRouteId);
  }

  /// Obtiene la fecha de la ruta guardada.
  DateTime? getSelectedRouteDate() {
    final dateStr = _prefs.getString(_keySelectedRouteDate);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Limpia la selección de ruta.
  Future<void> clearSelectedRoute() async {
    await _prefs.remove(_keySelectedRouteId);
    await _prefs.remove(_keySelectedRouteDate);
  }
}
