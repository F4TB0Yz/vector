import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';

abstract class MapRepository {
  /// Fetches the active route for the day.
  /// Returns a [RouteEntity] on success (Right) or a [Failure] on error (Left).
  Future<Either<Failure, RouteEntity>> getActiveRoute();

  Future<Either<Failure, RouteEntity>> getRouteById(String id);

  /// Optimizes the route order using OR-Tools (Python API)
  /// and persists the new order to the database.
  Future<Either<Failure, RouteEntity>> optimizeRoute({
    required String routeId,
    required Position startPoint,
    Position? endPoint,
    bool returnToStart = false,
  });
}
