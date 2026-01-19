import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
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
  PointAnnotationManager? _stopAnnotationManager;

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

    await loadActiveRoute();
  }

  Future<void> onMapCreated(MapboxMap mapboxMap) async {
    state = state.copyWith(mapController: mapboxMap, isMapReady: true);
    
    _stopAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();

    _configureMap(mapboxMap);
    await _enableLocationPuck();

    // Workaround for style loading issue: wait a bit before drawing.
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (state.activeRoute != null) {
      await _drawRoute(state.activeRoute!);
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
        // If map is already ready, draw the route.
        // The delay in onMapCreated should prevent most race conditions.
        if (state.isMapReady) {
          await _drawRoute(route);
        }
      },
    );
  }
  
  Future<void> _drawRoute(RouteEntity route) async {
    await _drawPolyline(route);
    await _drawStops(route);
    await _zoomToRoute(route);
  }

  Future<void> _drawPolyline(RouteEntity route) async {
    if (!state.isMapReady) return;
    final mapboxMap = state.mapController!;

    final routeGeoJSON = {
      'type': 'Feature',
      'geometry': LineString(coordinates: route.polyline).toJson(),
    };

    // Verificar si el source ya existe
    final sourceExists = await mapboxMap.style.styleSourceExists('route-source');
    
    if (sourceExists) {
      // Actualizar datos del source existente usando setStyleSourceProperty
      await mapboxMap.style.setStyleSourceProperty(
        'route-source',
        'data',
        jsonEncode(routeGeoJSON),
      );
    } else {
      // Crear el source por primera vez
      await mapboxMap.style.addSource(
        GeoJsonSource(id: 'route-source', data: jsonEncode(routeGeoJSON)),
      );
    }
    
    // Verificar si la capa ya existe antes de agregarla
    final layerExists = await mapboxMap.style.styleLayerExists('route-layer');
    
    if (!layerExists) {
      await mapboxMap.style.addLayer(LineLayer(
        id: 'route-layer',
        sourceId: 'route-source',
        lineColor: Colors.blue.toARGB32(),
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ));
    }
  }

  Future<void> _drawStops(RouteEntity route) async {
    if (_stopAnnotationManager == null) return;
    
    await _stopAnnotationManager!.deleteAll();
    final options = route.stops.map((stop) {
      return PointAnnotationOptions(
        geometry: Point(coordinates: stop.coordinates),
        textField: stop.name,
        textColor: Colors.white.toARGB32(),
        iconImage: "marker-icon",
      );
    }).toList();
    for (final option in options) {
      await _stopAnnotationManager!.create(option);
    }
  }

  Future<void> _zoomToRoute(RouteEntity route) async {
     if (route.polyline.isEmpty || !state.isMapReady) return;
     try {
       final bounds = await state.mapController!.cameraForCoordinates(
         route.polyline.map((p) => Point(coordinates: p)).toList(),
         MbxEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
         null,
         null,
       );
       await state.mapController!.easeTo(
         bounds,
         MapAnimationOptions(duration: 1500),
       );
     } catch(e) {
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
}

// --- PROVIDER ---
final mapProvider = NotifierProvider<MapNotifier, MapState>(() {
  return MapNotifier();
});