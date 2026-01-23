import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/address_entity.dart';

/// Repository interface for geocoding operations.
abstract class GeocodingRepository {
  /// Reverse geocode: Convert coordinates to a human-readable address.
  ///
  /// Returns [AddressEntity] on success, or [Failure] on error.
  Future<Either<Failure, AddressEntity>> reverseGeocode(Position coordinates);
}
