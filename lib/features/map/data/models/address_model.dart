import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/map/domain/entities/address_entity.dart';

/// Data model for address, mapping JSON from Mapbox Geocoding API response.
class AddressModel {
  final String placeName;
  final List<double> center;
  final String? street;
  final String? locality;
  final String? region;

  AddressModel({
    required this.placeName,
    required this.center,
    this.street,
    this.locality,
    this.region,
  });

  /// Parse JSON response from Mapbox Geocoding API.
  ///
  /// Expected format:
  /// ```json
  /// {
  ///   "features": [
  ///     {
  ///       "place_name": "Calle 10 #5-20, Fusagasugá, Cundinamarca",
  ///       "center": [-74.3636, 4.3369],
  ///       "context": [
  ///         {"id": "locality.xxx", "text": "Fusagasugá"},
  ///         {"id": "region.xxx", "text": "Cundinamarca"}
  ///       ]
  ///     }
  ///   ]
  /// }
  /// ```
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as List<dynamic>?;

    if (features == null || features.isEmpty) {
      throw FormatException('No features found in geocoding response');
    }

    final feature = features.first as Map<String, dynamic>;
    final placeName = feature['place_name'] as String;
    final center = (feature['center'] as List<dynamic>).cast<double>();

    // Extract context information (locality, region)
    String? locality;
    String? region;
    final context = feature['context'] as List<dynamic>?;

    if (context != null) {
      for (final item in context) {
        final contextItem = item as Map<String, dynamic>;
        final id = contextItem['id'] as String;
        final text = contextItem['text'] as String;

        if (id.startsWith('locality')) {
          locality = text;
        } else if (id.startsWith('region')) {
          region = text;
        }
      }
    }

    // Extract street from place_name (first part before comma)
    final street = placeName.split(',').first.trim();

    return AddressModel(
      placeName: placeName,
      center: center,
      street: street,
      locality: locality,
      region: region,
    );
  }

  /// Convert to domain entity.
  AddressEntity toEntity() {
    return AddressEntity(
      placeName: placeName,
      coordinates: Position(center[0], center[1]), // [lng, lat]
      street: street,
      locality: locality,
      region: region,
    );
  }
}
