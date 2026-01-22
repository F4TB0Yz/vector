import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/database/database_service.dart';
import 'package:vector/core/error/exceptions.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/data/datasources/map_datasource.dart';
import 'package:vector/features/map/data/datasources/route_remote_datasource.dart';
import 'package:vector/features/map/data/models/route_model.dart';
import 'package:vector/features/map/data/models/stop_model.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/repositories/map_repository.dart';

// Repository Implementation
class MapRepositoryImpl implements MapRepository {
  final MapDataSource remoteDataSource;
  final RouteRemoteDataSource routeRemoteDataSource;
  // final NetworkInfo networkInfo; // To check for connectivity

  MapRepositoryImpl({
    required this.remoteDataSource,
    required this.routeRemoteDataSource,
  });

  @override
  Future<Either<Failure, RouteEntity>> getActiveRoute() async {
    // Here you would check networkInfo.isConnected
    try {
      // 1. Get route with stops from local datasource
      final route = await remoteDataSource.getActiveRoute();

      // 2. Extract stop coordinates
      final stopPositions = route.stops
          .map((stop) => stop.coordinates)
          .toList();

      // 3. Fetch detailed polyline from Mapbox Directions API
      // This replaces straight lines with road-following geometry
      final detailedPolyline = await routeRemoteDataSource.getRoutePolyline(
        stopPositions,
      );

      // 4. Create new RouteEntity with detailed polyline
      final routeWithDetailedPolyline = RouteEntity(
        id: route.id,
        name: route.name,
        polyline: detailedPolyline, // ¡Ahora sigue las carreteras!
        stops: route.stops,
        progress: route.progress,
      );

      return Right(routeWithDetailedPolyline);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get active route: $e'));
    }
  }

  @override
  Future<Either<Failure, RouteEntity>> getRouteById(String id) async {
    try {
      final route = await remoteDataSource.getRouteById(id);
      final stopPositions = route.stops
          .map((stop) => stop.coordinates)
          .toList();

      // Intentar obtener polyline detallado (puede fallar si no hay internet, deberíamos manejar eso)
      List<Position> polyline;
      try {
        polyline = await routeRemoteDataSource.getRoutePolyline(stopPositions);
      } catch (e) {
        // Fallback a líneas rectas si falla Mapbox
        polyline = stopPositions;
      }

      final routeWithDetailedPolyline = RouteEntity(
        id: route.id,
        name: route.name,
        polyline: polyline,
        stops: route.stops,
        progress: route.progress,
      );

      return Right(routeWithDetailedPolyline);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to load route $id: $e'));
    }
  }
}

// Repository Implementation using database
class MapLocalDataSourceImpl implements MapDataSource {
  final DatabaseService databaseService;

  MapLocalDataSourceImpl(this.databaseService);

  @override
  Future<RouteEntity> getActiveRoute() async {
    try {
      final db = await databaseService.database;

      // Obtener la primera ruta (asumimos que solo hay una activa)
      final routeResults = await db.query(
        'routes',
        limit: 1,
        orderBy: 'created_at DESC',
      );

      if (routeResults.isEmpty) {
        throw ServerException('No active route found');
      }

      final routeMap = routeResults.first;

      // Obtener las paradas de esta ruta
      final stopResults = await db.query(
        'stops',
        where: 'route_id = ?',
        whereArgs: [routeMap['id']],
        orderBy: 'stop_order ASC',
      );

      final stops = stopResults
          .map((stopMap) => StopModel.fromMap(stopMap))
          .toList();

      final routeModel = RouteModel.fromMap(routeMap, stops: stops);
      return routeModel.toEntity();
    } catch (e) {
      throw ServerException('Failed to get active route: $e');
    }
  }

  @override
  Future<RouteEntity> getRouteById(String id) async {
    try {
      final db = await databaseService.database;

      final routeResults = await db.query(
        'routes',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (routeResults.isEmpty) {
        throw ServerException('Route not found');
      }

      final routeMap = routeResults.first;

      final stopResults = await db.query(
        'stops',
        where: 'route_id = ?',
        whereArgs: [id],
        orderBy: 'stop_order ASC',
      );

      final stops = stopResults
          .map((stopMap) => StopModel.fromMap(stopMap))
          .toList();

      final routeModel = RouteModel.fromMap(routeMap, stops: stops);
      return routeModel.toEntity();
    } catch (e) {
      throw ServerException('Failed to get route: $e');
    }
  }

  /// Fetches detailed route polyline from Mapbox Directions API
  Future<List<Position>> getDetailedPolyline(
    List<Position> stopPositions,
  ) async {
    // This would be injected if we had RouteRemoteDataSource here
    // For now, return stops as-is (will be handled in repository)
    return stopPositions;
  }
}
