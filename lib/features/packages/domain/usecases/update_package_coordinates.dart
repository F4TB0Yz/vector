import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/error/failures.dart';
import '../repositories/jt_package_repository.dart';

class UpdatePackageCoordinates {
  final JTPackageRepository repository;

  UpdatePackageCoordinates(this.repository);

  /// Actualiza las coordenadas de un paquete
  /// 
  /// [waybillNo] - Número de guía del paquete
  /// [coordinates] - Coordenadas a asignar
  /// 
  /// Retorna [Right(void)] si fue exitoso, o [Left(Failure)] si hubo error
  Future<Either<Failure, void>> call({
    required String waybillNo,
    required Position coordinates,
  }) async {
    // Validar coordenadas (deben estar dentro de Fusagasugá aproximadamente)
    final isValid = _validateCoordinates(coordinates);
    if (!isValid) {
      return const Left(
        ValidationFailure(
          'Las coordenadas deben estar dentro de Fusagasugá',
        ),
      );
    }

    return await repository.updatePackageCoordinates(waybillNo, coordinates);
  }

  /// Valida que las coordenadas estén aproximadamente en Fusagasugá
  /// Bounding box amplio para dar margen
  bool _validateCoordinates(Position coordinates) {
    const minLat = 4.2;
    const maxLat = 4.5;
    const minLng = -74.5;
    const maxLng = -74.0;

    return coordinates.lat >= minLat &&
        coordinates.lat <= maxLat &&
        coordinates.lng >= minLng &&
        coordinates.lng <= maxLng;
  }
}
