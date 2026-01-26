import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/database/database_service.dart';
import 'package:vector/core/error/exceptions.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/data/datasources/map_datasource.dart';
import 'package:vector/features/map/data/datasources/optimization_remote_datasource.dart';
import 'package:vector/features/map/data/datasources/route_remote_datasource.dart';
import 'package:vector/features/map/data/models/route_model.dart';
import 'package:vector/features/map/data/models/stop_model.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/repositories/map_repository.dart';
import 'package:vector/features/map/domain/repositories/stop_repository.dart';

// Repository Implementation
class MapRepositoryImpl implements MapRepository {
  final MapDataSource remoteDataSource;
  final RouteRemoteDataSource routeRemoteDataSource;
  final OptimizationRemoteDataSource optimizationRemoteDataSource;
  final StopRepository stopRepository;

  MapRepositoryImpl({
    required this.remoteDataSource,
    required this.routeRemoteDataSource,
    required this.optimizationRemoteDataSource,
    required this.stopRepository,
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

  @override
  Future<Either<Failure, RouteEntity>> optimizeRoute({
    required String routeId,
    required Position startPoint,
    Position? endPoint,
    bool returnToStart = false,
  }) async {
    try {
      _logInfo('🔄 Starting route optimization for ID: $routeId');

      // 1. Get current route data
      final route = await remoteDataSource.getRouteById(routeId);
      if (route.stops.isEmpty) {
        _logInfo('ℹ️ Route has no stops, nothing to optimize');
        return Right(route);
      }

      // 2. Prepare waypoints for optimization
      final waypoints = route.stops.map((s) => s.coordinates).toList();
      final effectiveEnd = returnToStart
          ? startPoint
          : (endPoint ?? waypoints.last);

      _logInfo('🛰️ Dispatching to Python OR-Tools API...');
      // 3. Call Python API for optimized order
      final optimizedIndices = await optimizationRemoteDataSource
          .getOptimizedOrder(
            waypoints: waypoints,
            start: startPoint,
            end: effectiveEnd,
          );

      // 4. Reorder stops based on API indices
      final reorderedStops = optimizedIndices
          .map((index) => route.stops[index])
          .toList();
      _logInfo('📦 Reordering ${reorderedStops.length} stops in database...');

      // Persist to database
      final orderedStopIds = reorderedStops.map((s) => s.id).toList();
      final reorderResult = await stopRepository.reorderStops(routeId, orderedStopIds);
      
      if (reorderResult.isLeft()) {
        _logError('❌ Failed to persist optimized order to database');
        // We continue anyway to show it on map, but log the error
      }

      // Update stopOrder field for the current entity
      final updatedStops = [];
      for (int i = 0; i < reorderedStops.length; i++) {
        updatedStops.add(reorderedStops[i].copyWith(stopOrder: i + 1));
      }

      _logInfo('🗺️ Fetching new road-accurate polyline from Mapbox...');
      // 5. Get NEW detailed polyline for the optimized order
      final newStopPositions = updatedStops.map((s) => s.coordinates).toList();

      // Polyline should go: START -> STOP 1 -> STOP 2 -> ... -> END
      final List<Position> fullPathPoints = [startPoint, ...newStopPositions];
      if (returnToStart)
        fullPathPoints.add(startPoint);
      else if (endPoint != null)
        fullPathPoints.add(endPoint);

      final detailedPolyline = await routeRemoteDataSource.getRoutePolyline(
        fullPathPoints,
      );

      _logInfo('✨ Optimization workflow complete');
      final optimizedRoute = RouteEntity(
        id: route.id,
        name: route.name,
        polyline: detailedPolyline,
        stops: updatedStops.cast(),
        progress: route.progress,
      );

      return Right(optimizedRoute);
    } catch (e) {
      _logError('❗ Repository optimization error: $e');
      return Left(ServerFailure('Optimization failed: $e'));
    }
  }

  void _logInfo(String message) {
    // ignore: avoid_print
    print('\x1B[32m[MapRepo] $message\x1B[0m');
  }

  void _logError(String message) {
    // ignore: avoid_print
    print('\x1B[31m[MapRepo] $message\x1B[0m');
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
