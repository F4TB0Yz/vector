import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/repositories/map_repository.dart';

class OptimizeRoute {
  final MapRepository repository;

  OptimizeRoute(this.repository);

  Future<Either<Failure, RouteEntity>> call({
    required String routeId,
    required Position startPoint,
    Position? endPoint,
    bool returnToStart = false,
  }) async {
    return await repository.optimizeRoute(
      routeId: routeId,
      startPoint: startPoint,
      endPoint: endPoint,
      returnToStart: returnToStart,
    );
  }
}
