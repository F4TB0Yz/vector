import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/error/exceptions.dart';
import '../models/route_model.dart';

abstract class RoutesLocalDataSource {
  Future<List<RouteModel>> getRoutes();
  Future<RouteModel> createRoute(String name, DateTime date);
}

class RoutesLocalDataSourceImpl implements RoutesLocalDataSource {
  final DatabaseService _databaseService;

  RoutesLocalDataSourceImpl(this._databaseService);

  @override
  Future<List<RouteModel>> getRoutes() async {
    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'routes',
        orderBy: 'created_at DESC',
      );
      return result.map((e) => RouteModel.fromJson(e)).toList();
    } catch (e) {
      throw const CacheException('Error al cargar rutas');
    }
  }

  @override
  Future<RouteModel> createRoute(String name, DateTime date) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now();
      final routeModel = RouteModel(
        id: const Uuid().v4(),
        name: name,
        date: date,
        progress: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      await db.insert(
        'routes',
        routeModel.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return routeModel;
    } catch (e) {
      throw const CacheException('Error al crear ruta');
    }
  }
}
