import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:turf/turf.dart' as turf;
import 'package:vector/core/utils/permission_handler.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';
import 'package:vector/features/map/presentation/providers/map_injection.dart';

// --- STATE ---
class MapState {
  final MapboxMap? mapController;
  final bool isMapReady;
  final bool isTracking;

  final geo.Position? userLocation;
  final geo.LocationPermission? locationPermission;

  final RouteEntity? activeRoute;
  final bool isLoadingRoute;

  final String? error;

  const MapState({
    this.mapController,
    this.isMapReady = false,
    this.isTracking = false,
    this.userLocation,
    this.locationPermission,
    this.activeRoute,
    this.isLoadingRoute = false,
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
      error: clearError ? null : error ?? this.error,
    );
  }
}

// --- NOTIFIER ---
class MapNotifier extends Notifier<MapState> {
  StreamSubscription<geo.Position>? _locationSubscription;
  bool _isUpdatingMapData = false;
  bool _sourcesInitialized = false;
  bool _routeProgressSourcesInitialized = false;

  @override
  MapState build() {
    ref.onDispose(() {
      _locationSubscription?.cancel();
    });
    return const MapState();
  }

  Future<void> init() async {
    final permission = await PermissionHandler.checkLocationPermission();
    state = state.copyWith(locationPermission: permission);

    if (permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse) {
      startTracking();
    }

    // Load route asynchronously without blocking initialization
    // ignore: unawaited_futures
    // loadActiveRoute(); // Comentado para obligar a la selección manual y mostrar placeholder
  }

  Future<void> onMapCreated(MapboxMap mapboxMap) async {
    state = state.copyWith(mapController: mapboxMap, isMapReady: true);

    _configureMap(mapboxMap);
    await _enableLocationPuck();

    // Workaround for style loading issue: wait a bit before drawing.
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (state.activeRoute != null) {
      await _updateMapData(state.activeRoute!);
    }
  }

  void _configureMap(MapboxMap mapboxMap) {
    mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));
  }

  Future<void> _enableLocationPuck() async {
    if (state.mapController == null) return;
    try {
      await state.mapController!.location.updateSettings(LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ));
    } catch (e) {
      state = state.copyWith(error: 'Error enabling location puck: $e');
    }
  }

  void startTracking() {
    if (state.isTracking) return;
    final locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 10,
    );
    _locationSubscription = geo.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      final firstLocation = state.userLocation == null;
      state = state.copyWith(userLocation: position, isTracking: true);
      if (firstLocation) {
         centerOnUserLocation();
      }
      
      // Update route progress in real-time
      _updateRouteProgress(position);
    }, onError: (e) {
      state = state.copyWith(error: "Error en stream de ubicación: $e", isTracking: false);
    });
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    state = state.copyWith(isTracking: false);
  }

  Future<void> loadActiveRoute() async {
    state = state.copyWith(isLoadingRoute: true);
    final repo = ref.read(mapRepositoryProvider);
    final result = await repo.getActiveRoute();

    result.fold(
      (failure) => state = state.copyWith(error: failure.message, isLoadingRoute: false),
      (route) async {
        state = state.copyWith(activeRoute: route, isLoadingRoute: false);
        // If map is already ready, update map data.
        // The delay in onMapCreated should prevent most race conditions.
        if (state.isMapReady) {
          await _updateMapData(route);
        }
      },
    );
  }

  Future<void> loadRouteById(String id) async {
    state = state.copyWith(isLoadingRoute: true);
    final repo = ref.read(mapRepositoryProvider);
    final result = await repo.getRouteById(id);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message, isLoadingRoute: false),
      (route) async {
        state = state.copyWith(activeRoute: route, isLoadingRoute: false);
        if (state.isMapReady) {
          await _updateMapData(route);
        }
      },
    );
  }
  
  /// Updates map data using GeoJSON sources (declarative approach)
  Future<void> _updateMapData(RouteEntity route) async {
    if (!state.isMapReady || state.mapController == null) return;
    
    // Prevenir llamadas concurrentes
    if (_isUpdatingMapData) return;
    _isUpdatingMapData = true;
    
    try {
      await _performMapDataUpdate(route);
    } finally {
      _isUpdatingMapData = false;
    }
  }
  
  Future<void> _performMapDataUpdate(RouteEntity route) async {
    final mapboxMap = state.mapController!;

    // 1. Preparar datos de LA RUTA (Línea)
    final routeGeoJSON = {
      'type': 'Feature',
      'properties': {},
      'geometry': LineString(coordinates: route.polyline).toJson(),
    };

    // 2. Preparar datos de LAS PARADAS (Puntos con propiedades)
    final features = route.stops.map((stop) {
      return {
        'type': 'Feature',
        'id': stop.id,
        'properties': {
          'stopOrder': stop.stopOrder.toString(),
          'status': stop.status.name,
          'customer': stop.name,
          'address': stop.address,
        },
        'geometry': Point(coordinates: stop.coordinates).toJson(),
      };
    }).toList();

    final stopsGeoJSON = {
      'type': 'FeatureCollection',
      'features': features,
    };

    // --- ACTUALIZACIÓN DE SOURCES ---
    
    if (!_sourcesInitialized) {
      // Primera vez: crear sources
      await mapboxMap.style.addSource(
        GeoJsonSource(id: 'route-source', data: jsonEncode(routeGeoJSON)),
      );
      await mapboxMap.style.addSource(
        GeoJsonSource(id: 'stops-source', data: jsonEncode(stopsGeoJSON)),
      );
      _sourcesInitialized = true;
    } else {
      // Actualizaciones subsecuentes: solo actualizar datos
      await mapboxMap.style.setStyleSourceProperty(
        'route-source',
        'data',
        jsonEncode(routeGeoJSON),
      );
      await mapboxMap.style.setStyleSourceProperty(
        'stops-source',
        'data',
        jsonEncode(stopsGeoJSON),
      );
    }

    // Llamamos a la creación de capas solo si no existen
    await _buildLayers(mapboxMap);
    
    // Zoom to route
    await _zoomToRoute(route);
  }

  /// Builds map layers for route and stops (only if they don't exist)
  Future<void> _buildLayers(MapboxMap mapboxMap) async {
    // Route Passed Layer (Gray - where we've been)
    if (!await mapboxMap.style.styleLayerExists('route-passed-layer')) {
      await mapboxMap.style.addLayer(LineLayer(
        id: 'route-passed-layer',
        sourceId: 'route-passed-source',
        lineColor: Colors.grey[800]!.toARGB32(),
        lineWidth: 4.0,
        lineOpacity: 0.5,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ));
    }

    // Route Active Layer (Neon - where we need to go)
    if (!await mapboxMap.style.styleLayerExists('route-active-layer')) {
      await mapboxMap.style.addLayer(LineLayer(
        id: 'route-active-layer',
        sourceId: 'route-active-source',
        lineColor: const Color(0xFF00FFFF).toARGB32(), // Neon cyan
        lineWidth: 6.0,
        lineOpacity: 1.0,
        lineCap: LineCap.ROUND,
        lineJoin: LineJoin.ROUND,
      ));
    }

    // Stops Layer (Circles with data-driven styling)
    if (!await mapboxMap.style.styleLayerExists('stops-layer')) {
      await mapboxMap.style.addLayer(CircleLayer(
        id: 'stops-layer',
        sourceId: 'stops-source',
        circleRadius: 12.0,
        circleColor: Colors.orange.toARGB32(),
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 2.0,
      ));
      
      // Apply data-driven styling for circle color based on status
      await mapboxMap.style.setStyleLayerProperty(
        'stops-layer',
        'circle-color',
        jsonEncode([
          'match',
          ['get', 'status'],
          'pending', '#FF9800',  // Orange
          'completed', '#4CAF50', // Green
          'failed', '#F44336',    // Red
          '#9E9E9E',              // Grey (default)
        ]),
      );
    }

    // Stops Labels Layer (Numbers)
    if (!await mapboxMap.style.styleLayerExists('stops-labels-layer')) {
      await mapboxMap.style.addLayer(SymbolLayer(
        id: 'stops-labels-layer',
        sourceId: 'stops-source',
        textField: '{stopOrder}',
        textSize: 12.0,
        textColor: Colors.white.toARGB32(),
        textHaloColor: Colors.black.toARGB32(),
        textHaloWidth: 1.0,
      ));
    }
  }

  Future<void> _zoomToRoute(RouteEntity route) async {
    if (route.polyline.isEmpty || !state.isMapReady) return;
    try {
      // Calculate bounds manually
      double minLat = route.polyline.first.lat.toDouble();
      double maxLat = route.polyline.first.lat.toDouble();
      double minLng = route.polyline.first.lng.toDouble();
      double maxLng = route.polyline.first.lng.toDouble();

      for (final point in route.polyline) {
        if (point.lat < minLat) minLat = point.lat.toDouble();
        if (point.lat > maxLat) maxLat = point.lat.toDouble();
        if (point.lng < minLng) minLng = point.lng.toDouble();
        if (point.lng > maxLng) maxLng = point.lng.toDouble();
      }

      // Calculate center
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;

      await state.mapController!.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(centerLng, centerLat)),
          zoom: 13.0,
        ),
        MapAnimationOptions(duration: 1500),
      );
    } catch (e) {
      state = state.copyWith(error: "Error al hacer zoom a la ruta: $e");
    }
  }


  Future<void> centerOnUserLocation() async {
    if (!state.isMapReady || state.userLocation == null) return;
    try {
      await state.mapController!.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(state.userLocation!.longitude, state.userLocation!.latitude)),
          zoom: 16.0,
          pitch: 45.0,
        ),
        MapAnimationOptions(duration: 1200),
      );
    } catch (e) {
      state = state.copyWith(error: "Error al centrar la cámara: $e");
    }
  }

  Future<void> zoomIn() async {
     // ...
  }

  Future<void> zoomOut() async {
    // ...
  }

  /// Updates route progress by splitting geometry into past and future segments
  Future<void> _updateRouteProgress(geo.Position userLocation) async {
    if (state.activeRoute == null || 
        !state.isMapReady || 
        state.activeRoute!.polyline.isEmpty) {
      return;
    }

    try {
      // 1. Convert Mapbox Polyline to Turf LineString
      final routeCoordinates = state.activeRoute!.polyline
          .map((p) => turf.Position.named(
                lat: p.lat.toDouble(),
                lng: p.lng.toDouble(),
              ))
          .toList();
      final routeLine = turf.LineString(coordinates: routeCoordinates);

      // 2. User point (Turf)
      final userPoint = turf.Point(
        coordinates: turf.Position.named(
          lat: userLocation.latitude,
          lng: userLocation.longitude,
        ),
      );

      // 3. Find nearest point on line (snap to road)
      final sliced = turf.nearestPointOnLine(routeLine, userPoint);

      // Access index from properties
      final index = sliced.properties?['index'] as int?;
      if (index == null) return;

      // 4. Split coordinates into two parts
      final splitIndex = index;

      // PAST: From start to split index + exact projected point
      final pastCoords = routeCoordinates.sublist(0, splitIndex + 1);
      pastCoords.add(sliced.geometry!.coordinates);

      // FUTURE: From exact projected point to end
      final futureCoords = <turf.Position>[sliced.geometry!.coordinates];
      futureCoords.addAll(routeCoordinates.sublist(splitIndex + 1));

      // 5. Update sources in Mapbox
      await _updateLayerSource('route-passed-source', pastCoords);
      await _updateLayerSource('route-active-source', futureCoords);
    } catch (e) {
      // Silently fail to avoid spamming errors during GPS updates
      // Only log in debug mode
      // ignore: avoid_print
      // print('Route progress update error: $e');
    }
  }

  /// Helper to update layer source without code duplication
  Future<void> _updateLayerSource(
    String sourceId,
    List<turf.Position> coords,
  ) async {
    if (!state.isMapReady || state.mapController == null) return;

    final mapboxMap = state.mapController!;

    // Convert Turf positions back to Mapbox format for GeoJSON
    final coordinates = coords
        .map((p) => [p.lng, p.lat]) // GeoJSON standard is [lng, lat]
        .toList();

    final geoJSON = {
      'type': 'Feature',
      'properties': {},
      'geometry': {
        'type': 'LineString',
        'coordinates': coordinates,
      },
    };

    try {
      if (!_routeProgressSourcesInitialized) {
        // First time: create sources
        if (!await mapboxMap.style.styleSourceExists(sourceId)) {
          await mapboxMap.style.addSource(
            GeoJsonSource(id: sourceId, data: jsonEncode(geoJSON)),
          );
        }
        // Mark as initialized after both sources are created
        if (sourceId == 'route-active-source') {
          _routeProgressSourcesInitialized = true;
        }
      } else {
        // Subsequent updates: only update data
        await mapboxMap.style.setStyleSourceProperty(
          sourceId,
          'data',
          jsonEncode(geoJSON),
        );
      }
    } catch (e) {
      // Silently handle errors to avoid spamming console
      // ignore: avoid_print
      // print('Error updating layer source $sourceId: $e');
    }
  }
}

// --- PROVIDER ---
final mapProvider = NotifierProvider<MapNotifier, MapState>(() {
  return MapNotifier();
});