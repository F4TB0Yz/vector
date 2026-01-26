import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:vector/features/map/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

/// Represents a request to create a new stop, typically initiated by a long-press on the map.
/// This object is used to hold the context for the confirmation UI.
class StopCreationRequest {
  final Point coordinates;
  final String? suggestedAddress;
  final String? customerName;
  final String? phone;
  final String? notes;
  final bool isGeocoding;

  const StopCreationRequest({
    required this.coordinates,
    this.suggestedAddress,
    this.customerName,
    this.phone,
    this.notes,
    this.isGeocoding = false,
  });

  StopCreationRequest copyWith({
    Point? coordinates,
    String? suggestedAddress,
    String? customerName,
    String? phone,
    String? notes,
    bool? isGeocoding,
  }) {
    return StopCreationRequest(
      coordinates: coordinates ?? this.coordinates,
      suggestedAddress: suggestedAddress ?? this.suggestedAddress,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      isGeocoding: isGeocoding ?? this.isGeocoding,
    );
  }
}

class MapState {
  final MapboxMap? mapController;
  final bool isMapReady;
  final bool isTracking;
  final bool isFollowMode;

  final geo.Position? userLocation;
  final geo.LocationPermission? locationPermission;

  final RouteEntity? activeRoute;
  final bool isLoadingRoute;
  final bool isOptimizing;

  final bool returnToStart;
  final Point? customEndLocation;

  final StopCreationRequest? stopCreationRequest;
  final StopEntity? selectedStop;
  final bool showRoutePolyline;

  final String? error;

  const MapState({
    this.mapController,
    this.isMapReady = false,
    this.isTracking = false,
    this.isFollowMode = false,
    this.userLocation,
    this.locationPermission,
    this.activeRoute,
    this.isLoadingRoute = false,
    this.isOptimizing = false,
    this.returnToStart = false,
    this.customEndLocation,
    this.stopCreationRequest,
    this.selectedStop,
    this.showRoutePolyline = false,
    this.error,
  });

  MapState copyWith({
    MapboxMap? mapController,
    bool? isMapReady,
    bool? isTracking,
    bool? isFollowMode,
    geo.Position? userLocation,
    geo.LocationPermission? locationPermission,
    RouteEntity? activeRoute,
    bool? isLoadingRoute,
    bool? isOptimizing,
    bool? returnToStart,
    Point? customEndLocation,
    StopCreationRequest? stopCreationRequest, // Nullable to allow updates
    StopEntity? selectedStop,
    bool? showRoutePolyline,
    bool clearStopCreationRequest = false,
    bool clearCustomEndLocation = false,
    bool clearSelectedStop = false,
    String? error,
    bool clearError = false,
  }) {
    return MapState(
      mapController: mapController ?? this.mapController,
      isMapReady: isMapReady ?? this.isMapReady,
      isTracking: isTracking ?? this.isTracking,
      isFollowMode: isFollowMode ?? this.isFollowMode,
      userLocation: userLocation ?? this.userLocation,
      locationPermission: locationPermission ?? this.locationPermission,
      activeRoute: activeRoute ?? this.activeRoute,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      isOptimizing: isOptimizing ?? this.isOptimizing,
      returnToStart: returnToStart ?? this.returnToStart,
      customEndLocation: clearCustomEndLocation
          ? null
          : (customEndLocation ?? this.customEndLocation),
      stopCreationRequest: clearStopCreationRequest
          ? null
          : (stopCreationRequest ?? this.stopCreationRequest),
      selectedStop: clearSelectedStop ? null : (selectedStop ?? this.selectedStop),
      showRoutePolyline: showRoutePolyline ?? this.showRoutePolyline,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

