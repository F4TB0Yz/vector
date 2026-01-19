import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/map/domain/repositories/stop_repository.dart';

/// Use case para obtener las paradas de una ruta.
class GetStopsByRoute {
  final StopRepository repository;

  GetStopsByRoute(this.repository);

  /// Ejecuta el use case.
  /// [routeId] ID de la ruta de la cual obtener las paradas.
  Future<Either<Failure, List<StopEntity>>> call(String routeId) async {
    if (routeId.isEmpty) {
      return Left(ValidationFailure('Route ID cannot be empty'));
    }

    return await repository.getStopsByRoute(routeId);
  }
}
