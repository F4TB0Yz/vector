import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/database/database_service.dart';
import 'package:vector/core/error/exceptions.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/data/datasources/map_datasource.dart';
import 'package:vector/features/map/data/models/route_model.dart';
import 'package:vector/features/map/data/models/stop_model.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/map/domain/repositories/map_repository.dart';

// Repository Implementation
class MapRepositoryImpl implements MapRepository {
  final MapDataSource remoteDataSource;
  // final MapDataSource localDataSource; // Could also have a local data source
  // final NetworkInfo networkInfo; // To check for connectivity

  MapRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, RouteEntity>> getActiveRoute() async {
    // Here you would check networkInfo.isConnected
    try {
      final route = await remoteDataSource.getActiveRoute();
      return Right(route);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
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
}
