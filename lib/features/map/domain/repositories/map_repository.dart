import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';

abstract class MapRepository {
  /// Fetches the active route for the day.
  /// Returns a [RouteEntity] on success (Right) or a [Failure] on error (Left).
  Future<Either<Failure, RouteEntity>> getActiveRoute();

  // Other methods like getRouteHistory, updateStopStatus, etc. could be added here.
}
