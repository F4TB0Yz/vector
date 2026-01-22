import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

abstract class RoutesRepository {
  Future<Either<Failure, List<RouteEntity>>> getRoutes();
  Future<Either<Failure, RouteEntity>> createRoute(String name, DateTime date);

  Future<Either<Failure, void>> addStop(String routeId, StopEntity stop);
}
