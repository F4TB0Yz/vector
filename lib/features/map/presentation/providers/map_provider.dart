import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:turf/turf.dart' as turf;
import 'package:vector/core/utils/permission_handler.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/map/domain/repositories/map_repository.dart';
import 'package:vector/features/map/domain/usecases/create_stop_from_coordinates.dart';
import 'package:vector/features/map/domain/usecases/optimize_route.dart';
import 'package:vector/features/map/domain/usecases/reverse_geocode_coordinates.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/map/presentation/providers/map_state.dart';

class MapProvider extends ChangeNotifier {
  final MapRepository _mapRepository;
  final ReverseGeocodeCoordinates _reverseGeocodeCoordinatesUseCase;
  final CreateStopFromCoordinates _createStopFromCoordinatesUseCase;
  final OptimizeRoute _optimizeRouteUseCase;

  MapState _mapState = const MapState();
  MapState get state => _mapState;

  StreamSubscription<geo.Position>? _locationSubscription;
  bool _isUpdatingMapData = false;
  bool _sourcesInitialized = false;
  bool _routeProgressSourcesInitialized = false;

  MapProvider({
    required MapRepository mapRepository,
    required ReverseGeocodeCoordinates reverseGeocodeCoordinatesUseCase,
    required CreateStopFromCoordinates createStopFromCoordinatesUseCase,
    required OptimizeRoute optimizeRouteUseCase,
  }) : _mapRepository = mapRepository,
       _reverseGeocodeCoordinatesUseCase = reverseGeocodeCoordinatesUseCase,
       _createStopFromCoordinatesUseCase = createStopFromCoordinatesUseCase,
       _optimizeRouteUseCase = optimizeRouteUseCase;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _updateState(MapState newState) {
    _mapState = newState;
    notifyListeners();
  }

  Future<void> init() async {
    final geo.LocationPermission permission =
        await PermissionHandler.checkLocationPermission();
    _updateState(state.copyWith(locationPermission: permission));

    if (permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse) {
      startTracking();
    }
  }

  Future<void> onMapCreated(MapboxMap mapboxMap) async {
    _updateState(state.copyWith(mapController: mapboxMap, isMapReady: true));

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

    // Asegurar que los gestos estén habilitados (Skill: Optimization/Map)
    mapboxMap.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: true,
        pinchToZoomEnabled: true,
        rotateEnabled: true,
        pitchEnabled: true,
        doubleTapToZoomInEnabled: true,
        quickZoomEnabled: true,
      ),
    );
  }

  Future<void> _enableLocationPuck() async {
    if (state.mapController == null) return;
    try {
      await state.mapController!.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );
    } catch (e) {
      _updateState(state.copyWith(error: 'Error enabling location puck: $e'));
    }
  }

  void startTracking() {
    if (state.isTracking) return;
    final geo.LocationSettings locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 5,
    );
    _locationSubscription =
        geo.Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          (geo.Position position) {
            final bool firstLocation = state.userLocation == null;
            _updateState(
              state.copyWith(userLocation: position, isTracking: true),
            );
            if (firstLocation) {
              centerOnUserLocation();
            }

            // Update route progress in real-time
            _updateRouteProgress(position);
          },
          onError: (Object e) {
            _updateState(
              state.copyWith(
                error: "Error en stream de ubicación: $e",
                isTracking: false,
              ),
            );
          },
        );
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _updateState(state.copyWith(isTracking: false));
  }

  Future<void> loadActiveRoute() async {
    _updateState(state.copyWith(isLoadingRoute: true));
    final result = await _mapRepository.getActiveRoute();

    result.fold(
      (failure) => _updateState(
        state.copyWith(error: failure.message, isLoadingRoute: false),
      ),
      (route) async {
        _updateState(state.copyWith(activeRoute: route, isLoadingRoute: false));
        // If map is already ready, update map data.
        if (state.isMapReady) {
          await _updateMapData(route);
        }
      },
    );
  }

  Future<void> loadRouteById(String id) async {
    _updateState(state.copyWith(isLoadingRoute: true));
    final result = await _mapRepository.getRouteById(id);

    result.fold(
      (failure) => _updateState(
        state.copyWith(error: failure.message, isLoadingRoute: false),
      ),
      (route) async {
        _updateState(state.copyWith(activeRoute: route, isLoadingRoute: false));
        if (state.isMapReady) {
          await _updateMapData(route);
        }
      },
    );
  }

  /// Updates map data using GeoJSON sources (declarative approach)
  Future<void> _updateMapData(
    RouteEntity route, {
    bool shouldZoom = true,
  }) async {
    if (!state.isMapReady || state.mapController == null) return;

    // Prevenir llamadas concurrentes
    if (_isUpdatingMapData) return;
    _isUpdatingMapData = true;

    try {
      await _performMapDataUpdate(route, shouldZoom: shouldZoom);
    } finally {
      _isUpdatingMapData = false;
    }
  }

  Future<void> _performMapDataUpdate(
    RouteEntity route, {
    bool shouldZoom = true,
  }) async {
    final MapboxMap mapboxMap = state.mapController!;
    final Map<String, dynamic> routeGeoJSON = _buildRouteGeoJSON(route);
    final Map<String, dynamic> stopsGeoJSON = _buildStopsGeoJSON(route);

    await _updateMapSources(mapboxMap, routeGeoJSON, stopsGeoJSON);
    await _buildLayers(mapboxMap);

    if (shouldZoom) {
      await _zoomToRoute(route);
    }
  }

  Map<String, dynamic> _buildRouteGeoJSON(RouteEntity route) {
    return {
      'type': 'Feature',
      'properties': <String, dynamic>{},
      'geometry': LineString(coordinates: route.polyline).toJson(),
    };
  }

  Map<String, dynamic> _buildStopsGeoJSON(RouteEntity route) {
    final List<Map<String, dynamic>> features = route.stops.map((stop) {
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

    return {'type': 'FeatureCollection', 'features': features};
  }

  Future<void> _updateMapSources(
    MapboxMap mapboxMap,
    Map<String, dynamic> routeGeoJSON,
    Map<String, dynamic> stopsGeoJSON,
  ) async {
    if (!_sourcesInitialized) {
      await mapboxMap.style.addSource(
        GeoJsonSource(id: 'route-source', data: jsonEncode(routeGeoJSON)),
      );
      await mapboxMap.style.addSource(
        GeoJsonSource(id: 'stops-source', data: jsonEncode(stopsGeoJSON)),
      );
      _sourcesInitialized = true;
    } else {
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
  }

  Future<void> _buildLayers(MapboxMap mapboxMap) async {
    await _addRoutePassedLayer(mapboxMap);
    await _addRouteActiveLayer(mapboxMap);
    await _addStopsLayer(mapboxMap);
    await _addStopsLabelsLayer(mapboxMap);
  }

  Future<void> _addRoutePassedLayer(MapboxMap mapboxMap) async {
    if (!await mapboxMap.style.styleLayerExists('route-passed-layer')) {
      await mapboxMap.style.addLayer(
        LineLayer(
          id: 'route-passed-layer',
          sourceId: 'route-passed-source',
          lineColor: Colors.grey[800]!.toARGB32(),
          lineWidth: 4.0,
          lineOpacity: 0.5,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    }
  }

  Future<void> _addRouteActiveLayer(MapboxMap mapboxMap) async {
    if (!await mapboxMap.style.styleLayerExists('route-active-layer')) {
      await mapboxMap.style.addLayer(
        LineLayer(
          id: 'route-active-layer',
          sourceId: 'route-active-source',
          lineColor: const Color(0xFF00FFFF).toARGB32(),
          lineWidth: 6.0,
          lineOpacity: 1.0,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
    }
  }

  Future<void> _addStopsLayer(MapboxMap mapboxMap) async {
    if (!await mapboxMap.style.styleLayerExists('stops-layer')) {
      await mapboxMap.style.addLayer(
        CircleLayer(
          id: 'stops-layer',
          sourceId: 'stops-source',
          circleRadius: 12.0,
          circleColor: Colors.orange.toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2.0,
        ),
      );
      await _applyStopsLayerStyle(mapboxMap);
    }
  }

  Future<void> _applyStopsLayerStyle(MapboxMap mapboxMap) async {
    await mapboxMap.style.setStyleLayerProperty(
      'stops-layer',
      'circle-color',
      jsonEncode([
        'match',
        ['get', 'status'],
        'pending',
        '#FF9800',
        'completed',
        '#4CAF50',
        'failed',
        '#F44336',
        '#9E9E9E',
      ]),
    );
  }

  Future<void> _addStopsLabelsLayer(MapboxMap mapboxMap) async {
    if (!await mapboxMap.style.styleLayerExists('stops-labels-layer')) {
      await mapboxMap.style.addLayer(
        SymbolLayer(
          id: 'stops-labels-layer',
          sourceId: 'stops-source',
          textField: '{stopOrder}',
          textSize: 12.0,
          textColor: Colors.white.toARGB32(),
          textHaloColor: Colors.black.toARGB32(),
          textHaloWidth: 1.0,
        ),
      );
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
      final double centerLat = (minLat + maxLat) / 2;
      final double centerLng = (minLng + maxLng) / 2;

      await state.mapController!.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(centerLng, centerLat)),
          zoom: 13.0,
        ),
        MapAnimationOptions(duration: 1500),
      );
    } catch (e) {
      _updateState(state.copyWith(error: "Error al hacer zoom a la ruta: $e"));
    }
  }

  Future<void> centerOnUserLocation() async {
    if (!state.isMapReady || state.userLocation == null) return;
    try {
      await state.mapController!.easeTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              state.userLocation!.longitude,
              state.userLocation!.latitude,
            ),
          ),
          zoom: 16.0,
          pitch: 45.0,
        ),
        MapAnimationOptions(duration: 1200),
      );
    } catch (e) {
      _updateState(state.copyWith(error: "Error al centrar la cámara: $e"));
    }
  }

  Future<void> onMapLongClick(Point point) async {
    // 1. Set initial state to show a loading indicator in the dialog
    _updateState(
      state.copyWith(
        stopCreationRequest: StopCreationRequest(
          coordinates: point,
          isGeocoding: true,
        ),
      ),
    );

    // 2. Call reverse geocoding use case
    final result = await _reverseGeocodeCoordinatesUseCase(point.coordinates);

    // 3. Update state with the result
    result.fold(
      (failure) {
        // If geocoding fails, show coordinates as fallback
        final String fallbackAddress =
            'Coordenadas: ${point.coordinates.lat.toStringAsFixed(6)}, ${point.coordinates.lng.toStringAsFixed(6)}';

        // Check if the user hasn't cancelled the dialog while geocoding
        if (state.stopCreationRequest?.coordinates.coordinates.toString() ==
            point.coordinates.toString()) {
          _updateState(
            state.copyWith(
              stopCreationRequest: state.stopCreationRequest!.copyWith(
                suggestedAddress: fallbackAddress,
                isGeocoding: false,
              ),
            ),
          );
        }
      },
      (address) {
        // Success: show the geocoded address
        if (state.stopCreationRequest?.coordinates.coordinates.toString() ==
            point.coordinates.toString()) {
          _updateState(
            state.copyWith(
              stopCreationRequest: state.stopCreationRequest!.copyWith(
                suggestedAddress: address.placeName,
                isGeocoding: false,
              ),
            ),
          );
        }
      },
    );
  }

  void cancelStopCreation() {
    _updateState(state.copyWith(clearStopCreationRequest: true));
  }

  Future<void> confirmStopCreation() async {
    if (state.stopCreationRequest == null || state.activeRoute == null) return;

    final StopCreationRequest request = state.stopCreationRequest!;
    final RouteEntity route = state.activeRoute!;

    // Clear the request from the state to hide the dialog immediately
    _updateState(
      state.copyWith(clearStopCreationRequest: true, isLoadingRoute: true),
    );

    // Call the use case
    final result = await _createStopFromCoordinatesUseCase(
      coordinates: request.coordinates,
      activeRoute: route,
      address: request.suggestedAddress,
    );

    result.fold(
      (failure) {
        _updateState(
          state.copyWith(
            error: 'Error al crear la parada: ${failure.message}',
            isLoadingRoute: false,
          ),
        );
      },
      (newStop) {
        // Success! Now, update the route in the state
        final List<StopEntity> updatedStops = List<StopEntity>.from(route.stops)
          ..add(newStop);
        final RouteEntity updatedRoute = route.copyWith(stops: updatedStops);

        _updateState(
          state.copyWith(activeRoute: updatedRoute, isLoadingRoute: false),
        );

        // And refresh the map visuals (without zooming)
        _updateMapData(updatedRoute, shouldZoom: false);
      },
    );
  }

  Future<void> zoomIn() async {
    if (!state.isMapReady || state.mapController == null) return;
    try {
      final CameraState currentCamera = await state.mapController!
          .getCameraState();
      final double currentZoom = currentCamera.zoom;

      await state.mapController!.easeTo(
        CameraOptions(zoom: currentZoom + 1.0),
        MapAnimationOptions(duration: 300),
      );
    } catch (e) {
      _updateState(state.copyWith(error: "Error al hacer zoom in: $e"));
    }
  }

  Future<void> zoomOut() async {
    if (!state.isMapReady || state.mapController == null) return;
    try {
      final CameraState currentCamera = await state.mapController!
          .getCameraState();
      final double currentZoom = currentCamera.zoom;

      await state.mapController!.easeTo(
        CameraOptions(zoom: currentZoom - 1.0),
        MapAnimationOptions(duration: 300),
      );
    } catch (e) {
      _updateState(state.copyWith(error: "Error al hacer zoom out: $e"));
    }
  }

  void toggleReturnToStart(bool value) {
    _updateState(state.copyWith(returnToStart: value));
  }

  void selectCustomEndLocation(Point point) {
    _updateState(state.copyWith(customEndLocation: point));
  }

  void clearCustomEndLocation() {
    _updateState(state.copyWith(clearCustomEndLocation: true));
  }

  Future<void> optimizeCurrentRoute() async {
    if (state.activeRoute == null || state.userLocation == null) {
      _updateState(state.copyWith(error: 'No hay ruta activa o ubicación GPS'));
      return;
    }

    _logInfo('🎬 Optimization triggered by user');
    _updateState(state.copyWith(isOptimizing: true, error: null));

    final Position userPos = Position(
      state.userLocation!.longitude,
      state.userLocation!.latitude,
    );

    final result = await _optimizeRouteUseCase(
      routeId: state.activeRoute!.id,
      startPoint: userPos,
      returnToStart: state.returnToStart,
      endPoint: state.customEndLocation?.coordinates,
    );

    result.fold(
      (failure) {
        _logError('❌ Provider optimization error: ${failure.message}');
        _updateState(
          state.copyWith(
            isOptimizing: false,
            error: 'Optimización fallida: ${failure.message}',
          ),
        );
      },
      (optimizedRoute) async {
        _logInfo('✅ Provider received optimized route. Updating state...');
        _updateState(
          state.copyWith(activeRoute: optimizedRoute, isOptimizing: false),
        );

        // Refresh map visuals
        await _updateMapData(optimizedRoute, shouldZoom: false);
        _logInfo('🗺️ Map visuals refreshed with optimized route');
      },
    );
  }

  void _logInfo(String message) {
    // ignore: avoid_print
    print('\x1B[35m[MapProvider] $message\x1B[0m');
  }

  void _logError(String message) {
    // ignore: avoid_print
    print('\x1B[31m[MapProvider] $message\x1B[0m');
  }

  void updatePackageStatus(String packageId, PackageStatus newStatus) {
    if (state.activeRoute == null) return;

    final List<StopEntity> updatedStops = state.activeRoute!.stops.map((stop) {
      if (stop.package.id == packageId) {
        final updatedPackage = stop.package.copyWith(status: newStatus);
        return stop.copyWith(package: updatedPackage);
      }
      return stop;
    }).toList();

    final RouteEntity updatedRoute = state.activeRoute!.copyWith(
      stops: updatedStops,
    );
    _updateState(state.copyWith(activeRoute: updatedRoute));

    // Trigger map update to reflect the new status (e.g., stop marker color change)
    _updateMapData(updatedRoute);
  }

  /// Updates route progress by splitting geometry into past and future segments
  Future<void> _updateRouteProgress(geo.Position userLocation) async {
    if (state.activeRoute == null ||
        !state.isMapReady ||
        state.activeRoute!.polyline.isEmpty) {
      return;
    }

    try {
      final turf.Feature<turf.Point> sliced = _getNearestPointOnRoute(
        userLocation,
      );
      final int? index = sliced.properties?['index'] as int?;
      if (index == null) return;

      final List<List<turf.Position>> segments = _splitRouteAtPoint(
        index,
        sliced,
      );

      await _updateLayerSource('route-passed-source', segments[0]);
      await _updateLayerSource('route-active-source', segments[1]);
    } catch (e) {
      // ignore: avoid_print
    }
  }

  turf.Feature<turf.Point> _getNearestPointOnRoute(geo.Position userLocation) {
    final List<turf.Position> routeCoordinates = state.activeRoute!.polyline
        .map(
          (p) =>
              turf.Position.named(lat: p.lat.toDouble(), lng: p.lng.toDouble()),
        )
        .toList();
    final turf.LineString routeLine = turf.LineString(
      coordinates: routeCoordinates,
    );
    final turf.Point userPoint = turf.Point(
      coordinates: turf.Position.named(
        lat: userLocation.latitude,
        lng: userLocation.longitude,
      ),
    );
    return turf.nearestPointOnLine(routeLine, userPoint);
  }

  List<List<turf.Position>> _splitRouteAtPoint(
    int splitIndex,
    turf.Feature<turf.Point> sliced,
  ) {
    final List<turf.Position> routeCoordinates = state.activeRoute!.polyline
        .map(
          (p) =>
              turf.Position.named(lat: p.lat.toDouble(), lng: p.lng.toDouble()),
        )
        .toList();

    // PAST
    final List<turf.Position> pastCoords = routeCoordinates.sublist(
      0,
      splitIndex + 1,
    );
    pastCoords.add(sliced.geometry!.coordinates);

    // FUTURE
    final List<turf.Position> futureCoords = <turf.Position>[
      sliced.geometry!.coordinates,
    ];
    futureCoords.addAll(routeCoordinates.sublist(splitIndex + 1));

    return [pastCoords, futureCoords];
  }

  /// Helper to update layer source without code duplication
  Future<void> _updateLayerSource(
    String sourceId,
    List<turf.Position> coords,
  ) async {
    if (!state.isMapReady || state.mapController == null) return;

    final MapboxMap mapboxMap = state.mapController!;
    final Map<String, dynamic> geoJSON = _prepareGeoJSON(coords);

    try {
      if (!_routeProgressSourcesInitialized) {
        await _initializeSource(mapboxMap, sourceId, geoJSON);
      } else {
        await _updateSourceData(mapboxMap, sourceId, geoJSON);
      }
    } catch (e) {
      // ignore: avoid_print
    }
  }

  Map<String, dynamic> _prepareGeoJSON(List<turf.Position> coords) {
    final List<List<double>> coordinates = coords
        .map((p) => [p.lng.toDouble(), p.lat.toDouble()])
        .toList();

    return {
      'type': 'Feature',
      'properties': <String, dynamic>{},
      'geometry': {'type': 'LineString', 'coordinates': coordinates},
    };
  }

  Future<void> _initializeSource(
    MapboxMap mapboxMap,
    String sourceId,
    Map<String, dynamic> geoJSON,
  ) async {
    if (!await mapboxMap.style.styleSourceExists(sourceId)) {
      await mapboxMap.style.addSource(
        GeoJsonSource(id: sourceId, data: jsonEncode(geoJSON)),
      );
    }
    if (sourceId == 'route-active-source') {
      _routeProgressSourcesInitialized = true;
    }
  }

  Future<void> _updateSourceData(
    MapboxMap mapboxMap,
    String sourceId,
    Map<String, dynamic> geoJSON,
  ) async {
    await mapboxMap.style.setStyleSourceProperty(
      sourceId,
      'data',
      jsonEncode(geoJSON),
    );
  }
}
