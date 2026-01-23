import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/map/domain/repositories/stop_repository.dart';
import 'package:vector/features/packages/domain/entities/manual_package_entity.dart';
import 'package:vector/features/packages/domain/entities/package_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';

/// Use case para crear una nueva parada a partir de coordenadas en el mapa.
class CreateStopFromCoordinates {
  final StopRepository repository;
  static const _uuid = Uuid();

  CreateStopFromCoordinates(this.repository);

  Future<Either<Failure, StopEntity>> call({
    required Point coordinates,
    required RouteEntity activeRoute,
    String? address,
  }) async {
    // Convert Point to Position
    final position = coordinates.coordinates;

    // 1. Crear un paquete por defecto
    final newPackage = ManualPackageEntity(
      id: _uuid.v4(),
      receiverName: 'Nuevo Paquete',
      address: address ?? 'Dirección no disponible',
      notes: 'Notas no disponibles',
      phone: '3132451121',
      coordinates: position,
      status: PackageStatus.pending,
      updatedAt: DateTime.now(),
    );

    // 2. Determinar el orden de la parada
    final newStopOrder = (activeRoute.stops.length) + 1;

    // 3. Crear la nueva entidad de parada
    final newStop = StopEntity(
      id: _uuid.v4(),
      routeId: activeRoute.id,
      stopOrder: newStopOrder,
      package: newPackage,
    );

    // 4. Llamar al repositorio para guardar la nueva parada
    return await repository.createStop(newStop);
  }
}
