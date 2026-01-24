import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:vector/features/map/domain/entities/route_entity.dart';

/// Represents a request to create a new stop, typically initiated by a long-press on the map.
/// This object is used to hold the context for the confirmation UI.
class StopCreationRequest {
  final Point coordinates;
  final String? suggestedAddress;
  final bool isGeocoding;

  const StopCreationRequest({
    required this.coordinates,
    this.suggestedAddress,
    this.isGeocoding = false,
  });

  StopCreationRequest copyWith({
    Point? coordinates,
    String? suggestedAddress,
    bool? isGeocoding,
  }) {
    return StopCreationRequest(
      coordinates: coordinates ?? this.coordinates,
      suggestedAddress: suggestedAddress ?? this.suggestedAddress,
      isGeocoding: isGeocoding ?? this.isGeocoding,
    );
  }
}

class MapState {
  final MapboxMap? mapController;
  final bool isMapReady;
  final bool isTracking;

  final geo.Position? userLocation;
  final geo.LocationPermission? locationPermission;

  final RouteEntity? activeRoute;
  final bool isLoadingRoute;

  final StopCreationRequest? stopCreationRequest;

  final String? error;

  const MapState({
    this.mapController,
    this.isMapReady = false,
    this.isTracking = false,
    this.userLocation,
    this.locationPermission,
    this.activeRoute,
    this.isLoadingRoute = false,
    this.stopCreationRequest,
    this.error,
  });

  MapState copyWith({
    MapboxMap? mapController,
    bool? isMapReady,
    bool? isTracking,
    geo.Position? userLocation,
    geo.LocationPermission? locationPermission,
    RouteEntity? activeRoute,
    bool? isLoadingRoute,
    StopCreationRequest? stopCreationRequest, // Nullable to allow updates
    bool clearStopCreationRequest = false,
    String? error,
    bool clearError = false,
  }) {
    return MapState(
      mapController: mapController ?? this.mapController,
      isMapReady: isMapReady ?? this.isMapReady,
      isTracking: isTracking ?? this.isTracking,
      userLocation: userLocation ?? this.userLocation,
      locationPermission: locationPermission ?? this.locationPermission,
      activeRoute: activeRoute ?? this.activeRoute,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      stopCreationRequest: clearStopCreationRequest
          ? null
          : (stopCreationRequest ?? this.stopCreationRequest),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
