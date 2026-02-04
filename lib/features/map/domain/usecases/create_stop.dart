import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/map/domain/repositories/stop_repository.dart';

/// Use case para crear una nueva parada.
class CreateStop {
  final StopRepository repository;
  static const _uuid = Uuid();

  CreateStop(this.repository);

  /// Ejecuta el use case.
  /// Si [stop.id] está vacío, se genera un UUID automáticamente.
  Future<Either<Failure, StopEntity>> call(StopEntity stop) async {
    // Validaciones
    if (stop.name.trim().isEmpty) {
      return const Left(ValidationFailure('Stop name cannot be empty'));
    }

    if (stop.address.trim().isEmpty) {
      return const Left(ValidationFailure('Stop address cannot be empty'));
    }

    // Generar ID si no existe
    final stopWithId = stop.id.isEmpty ? stop.copyWith(id: _uuid.v4()) : stop;

    return await repository.createStop(stopWithId);
  }
}
