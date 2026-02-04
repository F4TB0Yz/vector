import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/utils/permission_handler.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/map/domain/repositories/map_repository.dart';
import 'package:vector/features/map/domain/usecases/create_stop_from_coordinates.dart';
import 'package:vector/features/map/domain/usecases/optimize_route.dart';
import 'package:vector/features/map/domain/usecases/reverse_geocode_coordinates.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/map/presentation/providers/map_state.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart' as routes_entity;



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

  /// Ensures location permission is granted before executing an action.
  /// If permission is denied, it requests it.
  /// If permanently denied, it notifies the state.
  Future<bool> ensureLocationPermission() async {
    geo.LocationPermission permission =
        await PermissionHandler.checkLocationPermission();

    if (permission == geo.LocationPermission.denied) {
      permission = await PermissionHandler.requestLocationPermission();
    }

    _updateState(state.copyWith(locationPermission: permission));

    if (permission == geo.LocationPermission.deniedForever) {
      _updateState(
        state.copyWith(
          error:
              'Permiso de ubicación denegado permanentemente. Por favor, actívalo en ajustes.',
        ),
      );
      return false;
    }

    final granted =
        permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse;

    if (granted && !state.isTracking) {
      startTracking();
    }

    return granted;
  }

  Future<void> onMapCreated(MapboxMap mapboxMap) async {
    _updateState(state.copyWith(mapController: mapboxMap, isMapReady: true));

    _configureMap(mapboxMap);
    await _enableLocationPuck();
    await _loadMarkerIcons(mapboxMap);

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
    const geo.LocationSettings locationSettings = geo.LocationSettings(
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
            } else if (state.isFollowMode) {
              _moveCameraToUserLocation();
            }
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
    _updateState(
      state.copyWith(isLoadingRoute: true, showRoutePolyline: true),
    );
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
    _updateState(
      state.copyWith(isLoadingRoute: true, showRoutePolyline: true),
    );
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

  Future<void> _loadMarkerIcons(MapboxMap mapboxMap) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    const double size = 100.0;
    const double halfSize = size / 2;

    // Draw a Pin shape
    final Paint paint = Paint()..color = Colors.white;
    final Path path = Path();
    path.moveTo(halfSize, size); // Bottom tip
    path.quadraticBezierTo(size * 0.8, size * 0.6, size, halfSize);
    path.arcToPoint(
      const Offset(0, halfSize),
      radius: const Radius.circular(halfSize),
    );
    path.quadraticBezierTo(size * 0.2, size * 0.6, halfSize, size);
    path.close();

    canvas.drawPath(path, paint);

    final ui.Image image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData != null) {
      await mapboxMap.style.addStyleImage(
        'pin-marker',
        2.0, // Scale
        MbxImage(
          width: size.toInt(),
          height: size.toInt(),
          data: byteData.buffer.asUint8List(),
        ),
        true, // sdf: true allows us to recolor the icon using icon-color
        [],
        [],
        null,
      );
    }
  }

  Future<void> _performMapDataUpdate(

    RouteEntity route, {
    bool shouldZoom = true,
  }) async {
    final MapboxMap mapboxMap = state.mapController!;
    final Map<String, dynamic> routeGeoJSON = state.showRoutePolyline
        ? _buildRouteGeoJSON(route)
        : _buildEmptyLineStringGeoJSON();
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

  /// Returns a GeoJSON LineString feature with an empty coordinates list.
  /// Used to clear the route polyline from the map.
  Map<String, dynamic> _buildEmptyLineStringGeoJSON() {
    return {
      'type': 'Feature',
      'properties': const <String, dynamic>{},
      'geometry': LineString(coordinates: []).toJson(),
    };
  }

  Map<String, dynamic> _buildStopsGeoJSON(RouteEntity route) {
    final List<Map<String, dynamic>> features = route.stops.map((stop) {
      return {
        'type': 'Feature',
        'id': stop.id, // Feature ID is used for querying
        'properties': {
          'id': stop.id, // Also keep it in properties for redundancy
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
    await _addRouteLayer(mapboxMap);
    await _addStopsLayer(mapboxMap);
    // Remove _addStopsLabelsLayer since we'll integrate it into _addStopsLayer SymbolLayer
  } 

  Future<void> _addRouteLayer(MapboxMap mapboxMap) async {
    if (!await mapboxMap.style.styleLayerExists('route-layer')) {
      await mapboxMap.style.addLayer(
        LineLayer(
          id: 'route-layer',
          sourceId: 'route-source',
          lineColor: const ui.Color.fromARGB(255, 17, 142, 156).toARGB32(),
          lineWidth: 3.0,
          lineOpacity: 1.0,
          lineCap: LineCap.SQUARE,
          lineJoin: LineJoin.BEVEL,
        ),
      );
    }
  }

  Future<void> _addStopsLayer(MapboxMap mapboxMap) async {
    if (!await mapboxMap.style.styleLayerExists('stops-layer')) {
      // Create a SymbolLayer for markers
      await mapboxMap.style.addLayer(
        SymbolLayer(
          id: 'stops-layer',
          sourceId: 'stops-source',
          iconImage: 'pin-marker',
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: 0.5,
          iconAllowOverlap: true,
          iconPadding: 10, // Increase hit area
          textField: '{stopOrder}',
          textSize: 13.0,
          textColor: Colors.white.toARGB32(),
          textHaloColor: Colors.black.toARGB32(),
          textHaloWidth: 1.5,
          textFont: ['Open Sans Bold', 'Arial Unicode MS Bold'],
          textAnchor: TextAnchor.CENTER,
          textOffset: [0, -1.3],
          textIgnorePlacement: true,
          textAllowOverlap: true,
        ),
      );
      await _applyStopsLayerStyle(mapboxMap);
    }
  }

  Future<void> _applyStopsLayerStyle(MapboxMap mapboxMap) async {
    // For SymbolLayer, we use icon-color if the icon is a template image
    // or we can use different icons. For now, let's try icon-color.
    await mapboxMap.style.setStyleLayerProperty(
      'stops-layer',
      'icon-color',
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

  void selectStop(StopEntity stop) {
    _updateState(state.copyWith(selectedStop: stop));
  }

  void clearSelectedStop() {
    _updateState(state.copyWith(clearSelectedStop: true));
  }

  Future<void> onMapTap(ScreenCoordinate coordinate) async {
    if (state.mapController == null) return;

    final features = await state.mapController!.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(coordinate),
      RenderedQueryOptions(layerIds: ['stops-layer'], filter: null),
    );

    if (features.isNotEmpty) {
      final feature = features.first;
      if (feature?.queriedFeature.feature != null) {
        final Map<String, dynamic> featureJson = Map<String, dynamic>.from(feature!.queriedFeature.feature);
        final String? stopId = (featureJson['id'] ?? (featureJson['properties'] as Map?)?['id']) as String?;
        
        _logInfo('Feature tapped! stopId detected: $stopId');
        
        if (stopId != null && state.activeRoute != null) {
          try {
            final stop = state.activeRoute!.stops.firstWhere(
              (s) => s.id == stopId,
            );
            _logInfo('Stop found in route: ${stop.name}');
            selectStop(stop);
          } catch (e) {
            _logError('Stop not found in active route: $stopId. Available IDs: ${state.activeRoute!.stops.map((s) => s.id).join(', ')}');
          }
        }
      }
    } else {
      clearSelectedStop();
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
    if (!state.isMapReady) return;

    if (state.userLocation == null) {
      final hasPermission = await ensureLocationPermission();
      if (!hasPermission) return;
      // Wait a bit for the first location if we just started tracking
      if (state.userLocation == null) {
        _updateState(state.copyWith(error: "Obteniendo ubicación..."));
        return;
      }
    }

    _updateState(state.copyWith(isFollowMode: true));
    await _moveCameraToUserLocation(duration: 1200);
  }

  Future<void> _moveCameraToUserLocation({int duration = 1000}) async {
    if (state.mapController == null || state.userLocation == null) return;
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
        MapAnimationOptions(duration: duration),
      );
    } catch (e) {
      _logError("Error moving camera: $e");
    }
  }

  void disableFollowMode() {
    if (state.isFollowMode) {
      _updateState(state.copyWith(isFollowMode: false));
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

  Future<void> confirmStopCreation(
    RoutesProvider routesProvider, {
    String? customerName,
    String? address,
    String? phone,
    String? notes,
  }) async {
    if (state.stopCreationRequest == null || state.activeRoute == null) return;

    final StopCreationRequest request = state.stopCreationRequest!;
    final RouteEntity route = state.activeRoute!;

    // Clear the request from the state to hide the dialog immediately
    _updateState(
      state.copyWith(
        clearStopCreationRequest: true,
        isLoadingRoute: true,
        showRoutePolyline: state.showRoutePolyline,
      ),
    );

    // Call the use case
    final result = await _createStopFromCoordinatesUseCase(
      coordinates: request.coordinates,
      activeRoute: route,
      address: address ?? request.suggestedAddress,
      customerName: customerName,
      phone: phone,
      notes: notes,
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

        // SYNC: Update RoutesProvider to reflect changes in other screens (PackagesScreen, Route Summary)
        // routesProvider.updateRoute(updatedRoute);
        // FIXME: Type mismatch between Map RouteEntity and Routes RouteEntity. 
        // We will just invalidate RoutesProvider to force reload for now as a safer sync method,
        // or we could map it if we had all fields.
        // Since Map RouteEntity lacks 'date', 'createdAt', 'updatedAt', we can't easily convert it back 
        // to a full Routes RouteEntity without fetching those details or merging.
        
        // Strategy: Just tell RoutesProvider to reload the specific route from DB?
        // Or better: Since we just added a stop, let's trust that RoutesProvider can re-fetch or we pass the new stop.
        // Actually, for immediate UI update, we can assume the user wants to see the new stop in the list.
        
        // Temporary fix: Do not push full route object back to RoutesProvider if types mismatch.
        // Instead, rely on re-fetching or independent state updates if feasible.
        // But for "Add Stop", RoutesProvider usually handles the addition logic itself if called via its methods.
        // Here, MapProvider is calling CreateStop usecase directly. 
        
        // Let's use invalidate() if available or just trigger a reload.
        routesProvider.invalidate();

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

  Future<void> optimizeCurrentRoute(RoutesProvider routesProvider) async {
    if (state.activeRoute == null) {
      _updateState(state.copyWith(error: 'No hay ruta activa'));
      return;
    }

    if (state.userLocation == null) {
      final hasPermission = await ensureLocationPermission();
      if (!hasPermission) return;
      if (state.userLocation == null) {
        _updateState(state.copyWith(error: 'Esperando señal GPS para optimizar...'));
        return;
      }
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
          state.copyWith(
            activeRoute: optimizedRoute,
            isOptimizing: false,
            showRoutePolyline: true,
          ),
        );

        // SYNC: Update RoutesProvider to reflect changes in other screens
        // routesProvider.updateRoute(optimizedRoute);
        // Type Mismatch Fix: Invalidate to reload from source of truth (DB)
        routesProvider.invalidate();
        _logInfo('🔄 RoutesProvider synchronized with optimized route');

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
    _updateState(
      state.copyWith(
        activeRoute: updatedRoute,
        showRoutePolyline: state.showRoutePolyline,
      ),
    );

    // Trigger map update to reflect the new status (e.g., stop marker color change)
    _updateMapData(updatedRoute);
  }

  /// Synchronizes the map with an externally updated route (e.g. from RoutesProvider).
  /// This avoids re-fetching from the repository and ensures UI consistency.
  Future<void> syncRoute(routes_entity.RouteEntity route) async {
    if (state.activeRoute?.id != route.id) {
       // If IDs mismatch, it might be a route switch, but we'll trust the caller
       // or we could just update it.
    }
    
    // Convert routes_entity.RouteEntity (Routes Domain) to RouteEntity (Map Domain)
    // We map common fields. Map domain RouteEntity needs polyline, which Routes domain might not have fully populated
    // or we assume it does if it comes from backend/DB.
    // However, Routes RouteEntity DOES NOT have `polyline` property directly exposed in the file I read earlier?
    // Let's re-read Routes RouteEntity to be sure. 
    // Wait, I saw earlier Routes RouteEntity does NOT have polyline.
    // Map RouteEntity HAS polyline.
    // If we sync from Routes -> Map, we might LOSE the polyline if we just map simplistic fields?
    // Actually, if we just want to update status of stops, we can keep existing polyline.
    
    final currentPolyline = state.activeRoute?.polyline ?? [];
    
    final mapRoute = RouteEntity(
      id: route.id,
      name: route.name,
      polyline: currentPolyline, // Keep existing polyline to avoid losing map path
      stops: route.stops, // These stops have the updated status!
      progress: route.progress,
    );
    
    _updateState(state.copyWith(activeRoute: mapRoute));
    
    // Refresh map sources
    if (state.isMapReady) {
      await _updateMapData(mapRoute, shouldZoom: false);
    }
  }
}

