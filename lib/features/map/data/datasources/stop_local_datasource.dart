import 'package:sqflite/sqflite.dart';
import 'package:vector/core/database/database_service.dart';
import 'package:vector/core/error/exceptions.dart';
import 'package:vector/features/map/data/models/stop_model.dart';

/// DataSource local para operaciones de base de datos de paradas.
class StopLocalDataSource {
  final DatabaseService databaseService;

  StopLocalDataSource(this.databaseService);

  /// Obtiene todas las paradas de una ruta ordenadas por stopOrder.
  Future<List<StopModel>> getStopsByRoute(String routeId) async {
    try {
      final db = await databaseService.database;
      final results = await db.query(
        'stops',
        where: 'route_id = ?',
        whereArgs: [routeId],
        orderBy: 'stop_order ASC',
      );

      return results.map((map) => StopModel.fromMap(map)).toList();
    } catch (e) {
      throw VectorDatabaseException('Failed to get stops: $e');
    }
  }

  /// Crea una nueva parada.
  Future<StopModel> createStop(StopModel stop) async {
    try {
      final db = await databaseService.database;
      await db.insert(
        'stops',
        stop.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return stop;
    } catch (e) {
      throw VectorDatabaseException('Failed to create stop: $e');
    }
  }

  /// Actualiza una parada existente.
  Future<StopModel> updateStop(StopModel stop) async {
    try {
      final db = await databaseService.database;
      final updatedStop = StopModel(
        id: stop.id,
        routeId: stop.routeId,
        name: stop.name,
        address: stop.address,
        phone: stop.phone,
        notes: stop.notes,
        latitude: stop.latitude,
        longitude: stop.longitude,
        status: stop.status,
        stopOrder: stop.stopOrder,
        createdAt: stop.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await db.update(
        'stops',
        updatedStop.toMap(),
        where: 'id = ?',
        whereArgs: [stop.id],
      );

      return updatedStop;
    } catch (e) {
      throw VectorDatabaseException('Failed to update stop: $e');
    }
  }

  /// Elimina una parada.
  Future<void> deleteStop(String stopId) async {
    try {
      final db = await databaseService.database;
      await db.delete('stops', where: 'id = ?', whereArgs: [stopId]);
    } catch (e) {
      throw VectorDatabaseException('Failed to delete stop: $e');
    }
  }

  /// Reordena las paradas de una ruta.
  /// Usa una transacción para garantizar atomicidad.
  Future<void> reorderStops(String routeId, List<String> stopIds) async {
    try {
      final db = await databaseService.database;

      await db.transaction((txn) async {
        for (int i = 0; i < stopIds.length; i++) {
          await txn.update(
            'stops',
            {
              'stop_order': i + 1, // Base 1 para consistencia con RouteEntity
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ? AND route_id = ?',
            whereArgs: [stopIds[i], routeId],
          );
        }
      });
    } catch (e) {
      throw VectorDatabaseException('Failed to reorder stops: $e');
    }
  }
}
