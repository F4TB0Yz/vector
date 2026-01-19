import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/map/domain/repositories/stop_repository.dart';

/// Use case para actualizar una parada existente.
class UpdateStop {
  final StopRepository repository;

  UpdateStop(this.repository);

  /// Ejecuta el use case.
  Future<Either<Failure, StopEntity>> call(StopEntity stop) async {
    // Validaciones
    if (stop.id.isEmpty) {
      return Left(ValidationFailure('Stop ID cannot be empty'));
    }

    if (stop.name.trim().isEmpty) {
      return Left(ValidationFailure('Stop name cannot be empty'));
    }

    if (stop.address.trim().isEmpty) {
      return Left(ValidationFailure('Stop address cannot be empty'));
    }

    return await repository.updateStop(stop);
  }
}
