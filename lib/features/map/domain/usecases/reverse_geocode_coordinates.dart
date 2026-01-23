import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/address_entity.dart';
import 'package:vector/features/map/domain/repositories/geocoding_repository.dart';

/// Use case for reverse geocoding: converting coordinates to an address.
class ReverseGeocodeCoordinates {
  final GeocodingRepository repository;

  ReverseGeocodeCoordinates(this.repository);

  /// Execute the use case.
  ///
  /// [coordinates] The geographic position to reverse geocode.
  ///
  /// Returns [AddressEntity] on success, or [Failure] on error.
  Future<Either<Failure, AddressEntity>> call(Position coordinates) async {
    return await repository.reverseGeocode(coordinates);
  }
}
