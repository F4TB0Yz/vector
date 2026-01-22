import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/error/exceptions.dart';
import '../models/route_model.dart';
import 'package:vector/features/map/data/models/stop_model.dart';

abstract class RoutesLocalDataSource {
  Future<List<RouteModel>> getRoutes();
  Future<RouteModel> createRoute(String name, DateTime date);
  Future<void> addStop(String routeId, StopModel stop);
}

class RoutesLocalDataSourceImpl implements RoutesLocalDataSource {
  final DatabaseService _databaseService;

  RoutesLocalDataSourceImpl(this._databaseService);

  @override
  Future<List<RouteModel>> getRoutes() async {
    try {
      final db = await _databaseService.database;

      // 1. Fetch all routes
      final List<Map<String, dynamic>> routeMaps = await db.query(
        'routes',
        orderBy: 'created_at DESC',
      );
      if (routeMaps.isEmpty) return [];

      // 2. Fetch all stops
      final List<Map<String, dynamic>> stopMaps = await db.query('stops');

      // 3. Group stops by route_id
      final Map<String, List<StopEntity>> stopsByRouteId = {};
      for (final stopMap in stopMaps) {
        // Create the data model from the map
        final stopModel = StopModel.fromMap(stopMap);
        // Get the domain entity
        final stopEntity = stopModel.toEntity();
        final routeId = stopModel.routeId;

        if (!stopsByRouteId.containsKey(routeId)) {
          stopsByRouteId[routeId] = [];
        }
        stopsByRouteId[routeId]!.add(stopEntity);
      }

      // 4. Attach stops to routes
      final List<RouteModel> routes = [];
      for (final routeMap in routeMaps) {
        final routeId = routeMap['id'] as String;
        final routeStops = stopsByRouteId[routeId] ?? [];

        // Use the fromMap factory to construct the RouteModel with its stops
        routes.add(RouteModel.fromMap(routeMap, stops: routeStops));
      }

      return routes;
    } catch (e) {
      throw CacheException('Error al cargar rutas con paradas: $e');
    }
  }

  @override
  Future<RouteModel> createRoute(String name, DateTime date) async {
    try {
      final db = await _databaseService.database; // Added this line
      final id = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;

      final route = RouteModel(
        id: id,
        name: name,
        date: date,
        progress: 0.0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(now),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );

      await db.insert(
        'routes',
        route.toJson()
          ..['date'] = date.millisecondsSinceEpoch
          ..['created_at'] = now
          ..['updated_at'] = now,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return route;
    } catch (e) {
      throw CacheException('Failed to create route: $e');
    }
  }

  @override
  Future<void> addStop(String routeId, StopModel stop) async {
    try {
      final db = await _databaseService.database;

      // Ensure stop has route_id set or pass it explicitly in map
      final stopMap = stop.toMap();
      stopMap['route_id'] = routeId;
      stopMap['created_at'] = DateTime.now().millisecondsSinceEpoch;
      stopMap['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        'stops',
        stopMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to add stop: $e');
    }
  }
}
