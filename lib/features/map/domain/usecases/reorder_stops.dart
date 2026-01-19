import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/repositories/stop_repository.dart';

/// Use case para reordenar las paradas de una ruta.
class ReorderStops {
  final StopRepository repository;

  ReorderStops(this.repository);

  /// Ejecuta el use case.
  /// [routeId] ID de la ruta.
  /// [stopIds] Lista de IDs de paradas en el nuevo orden deseado.
  Future<Either<Failure, void>> call(
    String routeId,
    List<String> stopIds,
  ) async {
    if (routeId.isEmpty) {
      return Left(ValidationFailure('Route ID cannot be empty'));
    }

    if (stopIds.isEmpty) {
      return Left(ValidationFailure('Stop IDs list cannot be empty'));
    }

    return await repository.reorderStops(routeId, stopIds);
  }
}
