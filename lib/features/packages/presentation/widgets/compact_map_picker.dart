import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';

/// Widget de mapa compacto que permite seleccionar coordenadas mediante tap
class CompactMapPicker extends StatefulWidget {
  final Position? initialPosition;
  final ValueChanged<Position> onCoordinatesSelected;

  const CompactMapPicker({
    super.key,
    this.initialPosition,
    required this.onCoordinatesSelected,
  });

  @override
  State<CompactMapPicker> createState() => _CompactMapPickerState();
}

class _CompactMapPickerState extends State<CompactMapPicker> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  PointAnnotation? _marker;

  // Coordenadas de Fusagasugá (fallback)
  final _fusagasugaCenter = Position(-74.3636, 4.3369);
  Position? _userLocation;
  bool _isLoadingLocation = true;

  // Keys para SharedPreferences
  static const String _latKey = 'cached_user_lat';
  static const String _lngKey = 'cached_user_lng';

  @override
  void initState() {
    super.initState();
    _loadCachedLocationAndUpdate();
  }

  Future<void> _loadCachedLocationAndUpdate() async {
    // Primero cargar ubicación en caché si existe
    final prefs = await SharedPreferences.getInstance();
    final cachedLat = prefs.getDouble(_latKey);
    final cachedLng = prefs.getDouble(_lngKey);

    if (cachedLat != null && cachedLng != null) {
      setState(() {
        _userLocation = Position(cachedLng, cachedLat);
        _isLoadingLocation = false;
      });

      // Centrar mapa si ya está creado
      if (_mapboxMap != null) {
        _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(coordinates: _userLocation!),
            zoom: 16.0,
          ),
          MapAnimationOptions(duration: 500),
        );
      }
    }

    // Luego obtener ubicación actual en segundo plano
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permisos
      final permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        await geo.Geolocator.requestPermission();
      }

      // Obtener ubicación actual
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      final newLocation = Position(position.longitude, position.latitude);
      
      // Guardar en caché
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_latKey, position.latitude);
      await prefs.setDouble(_lngKey, position.longitude);

      setState(() {
        _userLocation = newLocation;
        _isLoadingLocation = false;
      });

      // Centrar mapa en ubicación actual si ya está creado
      if (_mapboxMap != null && _userLocation != null) {
        _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(coordinates: _userLocation!),
            zoom: 16.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determinar posición inicial del mapa
    final initialPos = widget.initialPosition ?? _userLocation ?? _fusagasugaCenter;

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              MapWidget(
                key: const ValueKey('coordinate_picker_map'),
                styleUri: MapboxStyles.DARK,
                cameraOptions: CameraOptions(
                  center: Point(coordinates: initialPos),
                  zoom: 16.0,
                ),
                onMapCreated: _onMapCreated,
                onTapListener: _onMapTap,
                // IMPORTANTE: Solo habilitar Tap y LongPress para evitar conflicto con scroll
                // Pan y Scale interferirían con el scroll de la pantalla
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<TapGestureRecognizer>(
                    () => TapGestureRecognizer(),
                  ),
                  Factory<LongPressGestureRecognizer>(
                    () => LongPressGestureRecognizer(),
                  ),
                },
              ),
              // Indicador de carga de ubicación (solo si está calculando)
              if (_isLoadingLocation && _userLocation == null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Obteniendo ubicación...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
   
    // Ocultar logo de Mapbox
    await _mapboxMap!.logo.updateSettings(LogoSettings(
      enabled: false,
    ));

    // Ocultar scale bar (medidor)
    await _mapboxMap!.scaleBar.updateSettings(ScaleBarSettings(
      enabled: false,
    ));

    // Crear annotation manager para markers
    _annotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();

    // Si hay posición inicial, mostrar marker
    if (widget.initialPosition != null) {
      _addMarker(widget.initialPosition!);
    }

    // Si obtuvimos ubicación del usuario (de caché o actual), centrar ahí
    if (_userLocation != null) {
      _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: _userLocation!),
          zoom: 16.0,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  void _onMapTap(MapContentGestureContext context) {
    final coordinates = context.point.coordinates;
    
    // Crear Position desde coordenadas
    final position = Position(coordinates.lng, coordinates.lat);
    
    // Actualizar marker en el mapa
    _addMarker(position);
    
    // Notificar coordenadas seleccionadas
    widget.onCoordinatesSelected(position);
  }

  Future<void> _addMarker(Position position) async {
    if (_annotationManager == null) return;

    // Remover marker anterior si existe
    if (_marker != null) {
      await _annotationManager!.delete(_marker!);
    }

    // Crear nuevo marker con estilo neon
    _marker = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: position),
        iconSize: 1.5,
        iconColor: AppColors.primary.value,
        iconOpacity: 1.0,
      ),
    );
  }

  @override
  void dispose() {
    // Los managers se limpian automáticamente con dispose del mapa
    super.dispose();
  }
}
