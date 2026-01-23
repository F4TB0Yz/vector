import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Entity representing a geocoded address from coordinates.
class AddressEntity extends Equatable {
  /// Full formatted address (e.g., "Calle 10 #5-20, Fusagasugá, Cundinamarca")
  final String placeName;

  /// Geographic coordinates of the address
  final Position coordinates;

  /// Optional: Street name extracted from the address
  final String? street;

  /// Optional: Locality/City name
  final String? locality;

  /// Optional: Region/State name
  final String? region;

  const AddressEntity({
    required this.placeName,
    required this.coordinates,
    this.street,
    this.locality,
    this.region,
  });

  @override
  List<Object?> get props => [placeName, coordinates, street, locality, region];
}
