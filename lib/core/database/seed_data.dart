import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:vector/core/database/database_service.dart';

/// Puebla la base de datos con datos de ejemplo para desarrollo.
/// Solo se ejecuta si la base de datos está vacía.
class SeedData {
  static const _uuid = Uuid();

  /// Ejecuta el seeding de datos de ejemplo.
  static Future<void> seed() async {
    final db = await DatabaseService.instance.database;

    // Verificar si ya hay datos
    final routeCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM routes'),
    );

    if (routeCount != null && routeCount > 0) {
      // Ya hay datos, no hacer nada
      return;
    }

    // Crear ruta de ejemplo
    final routeId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('routes', {
      'id': routeId,
      'name': 'Ruta de Hoy',
      'date': now,
      'progress': 0.0,
      'created_at': now,
      'updated_at': now,
    });

    // Crear paradas de ejemplo en Fusagasugá
    final stops = [
      {
        'id': _uuid.v4(),
        'route_id': routeId,
        'name': 'Centro Comercial',
        'address': 'Calle 6 #5-20, Fusagasugá',
        'latitude': 4.3369,
        'longitude': -74.3636,
        'status': 'pending',
        'stop_order': 0,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': _uuid.v4(),
        'route_id': routeId,
        'name': 'Parque Principal',
        'address': 'Carrera 5 #10-15, Fusagasugá',
        'latitude': 4.34,
        'longitude': -74.36,
        'status': 'pending',
        'stop_order': 1,
        'created_at': now,
        'updated_at': now,
      },
      {
        'id': _uuid.v4(),
        'route_id': routeId,
        'name': 'Terminal de Buses',
        'address': 'Calle 15 #8-30, Fusagasugá',
        'latitude': 4.345,
        'longitude': -74.365,
        'status': 'pending',
        'stop_order': 2,
        'created_at': now,
        'updated_at': now,
      },
    ];

    for (final stop in stops) {
      await db.insert('stops', stop);
    }
  }
}
