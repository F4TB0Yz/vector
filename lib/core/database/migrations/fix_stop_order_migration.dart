import 'package:vector/core/database/database_service.dart';
import 'package:vector/core/error/exceptions.dart';

/// Utilidad para reparar el orden de las paradas en la base de datos.
/// 
/// Esta migración:
/// 1. Obtiene todas las rutas
/// 2. Para cada ruta, obtiene todas sus paradas
/// 3. Ordena las paradas por created_at (orden de creación)
/// 4. Asigna stopOrder secuencial (1, 2, 3, 4...)
/// 5. Actualiza la base de datos usando una transacción
class FixStopOrderMigration {
  final DatabaseService _databaseService;

  FixStopOrderMigration(this._databaseService);

  /// Ejecuta la migración para reparar el orden de todas las paradas.
  /// 
  /// Retorna el número total de paradas actualizadas.
  /// Lanza [VectorDatabaseException] si ocurre un error.
  Future<int> execute() async {
    try {
      _logInfo('🔧 Iniciando migración de stopOrder...');
      
      final db = await _databaseService.database;
      int totalUpdated = 0;

      // 1. Obtener todas las rutas
      final routeResults = await db.query('routes');
      _logInfo('📋 Encontradas ${routeResults.length} rutas');

      // 2. Para cada ruta, reordenar sus paradas
      for (final routeMap in routeResults) {
        final routeId = routeMap['id'] as String;
        final routeName = routeMap['name'] as String;

        // 3. Obtener paradas de esta ruta ordenadas por created_at
        final stopResults = await db.query(
          'stops',
          where: 'route_id = ?',
          whereArgs: [routeId],
          orderBy: 'created_at ASC', // Orden de creación
        );

        if (stopResults.isEmpty) {
          _logInfo('  ⏭️ Ruta "$routeName" sin paradas, omitiendo...');
          continue;
        }

        _logInfo('  🔄 Reordenando ${stopResults.length} paradas de "$routeName"...');

        // 4. Actualizar stopOrder usando transacción
        await db.transaction((txn) async {
          for (int i = 0; i < stopResults.length; i++) {
            final stopId = stopResults[i]['id'] as String;
            final newStopOrder = i + 1; // Base 1

            await txn.update(
              'stops',
              {
                'stop_order': newStopOrder,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              },
              where: 'id = ?',
              whereArgs: [stopId],
            );
          }
        });

        totalUpdated += stopResults.length;
        _logInfo('  ✅ Actualizadas ${stopResults.length} paradas de "$routeName"');
      }

      _logSuccess('✨ Migración completada: $totalUpdated paradas actualizadas');
      return totalUpdated;
    } catch (e) {
      _logError('❌ Error en migración: $e');
      throw VectorDatabaseException('Failed to fix stop order: $e');
    }
  }

  void _logInfo(String message) {
    // ignore: avoid_print
    print('\x1B[36m[StopOrderMigration] $message\x1B[0m'); // Cyan
  }

  void _logSuccess(String message) {
    // ignore: avoid_print
    print('\x1B[32m[StopOrderMigration] $message\x1B[0m'); // Green
  }

  void _logError(String message) {
    // ignore: avoid_print
    print('\x1B[31m[StopOrderMigration] $message\x1B[0m'); // Red
  }
}
