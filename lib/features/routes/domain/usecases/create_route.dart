import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/route_entity.dart';
import '../repositories/routes_repository.dart';

class CreateRoute {
  final RoutesRepository repository;

  CreateRoute(this.repository);

  Future<Either<Failure, RouteEntity>> call(String name, DateTime date) {
    return repository.createRoute(name, date);
  }
}
