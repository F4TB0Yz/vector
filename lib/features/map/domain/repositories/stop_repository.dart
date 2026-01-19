import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

/// Repositorio para operaciones CRUD de paradas.
abstract class StopRepository {
  /// Obtiene todas las paradas de una ruta específica.
  /// Retorna las paradas ordenadas por [stopOrder].
  Future<Either<Failure, List<StopEntity>>> getStopsByRoute(String routeId);

  /// Crea una nueva parada.
  /// Retorna la parada creada con su ID generado.
  Future<Either<Failure, StopEntity>> createStop(StopEntity stop);

  /// Actualiza una parada existente.
  /// Retorna la parada actualizada.
  Future<Either<Failure, StopEntity>> updateStop(StopEntity stop);

  /// Elimina una parada por su ID.
  Future<Either<Failure, void>> deleteStop(String stopId);

  /// Reordena las paradas de una ruta.
  /// [stopIds] debe contener todos los IDs de las paradas en el nuevo orden.
  Future<Either<Failure, void>> reorderStops(
    String routeId,
    List<String> stopIds,
  );
}
