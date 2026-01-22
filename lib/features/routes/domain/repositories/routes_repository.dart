import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/route_entity.dart';

abstract class RoutesRepository {
  Future<Either<Failure, List<RouteEntity>>> getRoutes();
  Future<Either<Failure, RouteEntity>> createRoute(String name, DateTime date);
}
