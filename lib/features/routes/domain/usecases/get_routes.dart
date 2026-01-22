import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/route_entity.dart';
import '../repositories/routes_repository.dart';

class GetRoutes {
  final RoutesRepository repository;

  GetRoutes(this.repository);

  Future<Either<Failure, List<RouteEntity>>> call() {
    return repository.getRoutes();
  }
}
