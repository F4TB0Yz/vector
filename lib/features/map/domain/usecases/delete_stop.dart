import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/repositories/stop_repository.dart';

/// Use case para eliminar una parada.
class DeleteStop {
  final StopRepository repository;

  DeleteStop(this.repository);

  /// Ejecuta el use case.
  Future<Either<Failure, void>> call(String stopId) async {
    if (stopId.isEmpty) {
      return Left(ValidationFailure('Stop ID cannot be empty'));
    }

    return await repository.deleteStop(stopId);
  }
}
