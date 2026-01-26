import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Pantalla fullscreen para seleccionar coordenadas en el mapa
class FullscreenMapPickerScreen extends StatefulWidget {
  final Position? initialPosition;

  const FullscreenMapPickerScreen({
    super.key,
    this.initialPosition,
  });

  @override
  State<FullscreenMapPickerScreen> createState() => _FullscreenMapPickerScreenState();
}

class _FullscreenMapPickerScreenState extends State<FullscreenMapPickerScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  PointAnnotation? _marker;

  // Coordenadas de Fusagasugá (fallback)
  final _fusagasugaCenter = Position(-74.3636, 4.3369);
  Position? _userLocation;
  Position? _selectedCoordinates;
  bool _isLoadingLocation = true;
  bool _isImageLoaded = false;

  // Keys para SharedPreferences
  static const String _latKey = 'cached_user_lat';
  static const String _lngKey = 'cached_user_lng';
  static const String _markerImageId = 'lollipop-marker';

  @override
  void initState() {
    super.initState();
    _selectedCoordinates = widget.initialPosition;
    _loadCachedLocationAndUpdate();
  }

  Future<void> _loadCachedLocationAndUpdate() async {
    // Primero cargar ubicación en caché si existe
    final prefs = await SharedPreferences.getInstance();
    final cachedLat = prefs.getDouble(_latKey);
    final cachedLng = prefs.getDouble(_lngKey);

    if (cachedLat != null && cachedLng != null) {
      if (!mounted) return;
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
      final permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        await geo.Geolocator.requestPermission();
      }

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

      if (!mounted) return;
      setState(() {
        _userLocation = newLocation;
        _isLoadingLocation = false;
      });

      // Centrar mapa en ubicación actual si ya está creado y no hay posición inicial
      if (_mapboxMap != null && _userLocation != null && widget.initialPosition == null) {
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
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialPos = widget.initialPosition ?? _userLocation ?? _fusagasugaCenter;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Mapa fullscreen
            Positioned.fill(
              child: MapWidget(
                key: const ValueKey('fullscreen_map_picker'),
                styleUri: MapboxStyles.DARK,
                cameraOptions: CameraOptions(
                  center: Point(coordinates: initialPos),
                  zoom: 16.0,
                ),
                onMapCreated: _onMapCreated,
                onTapListener: _onMapTap,
                // Todos los gestos habilitados en pantalla completa
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<PanGestureRecognizer>(
                    () => PanGestureRecognizer(),
                  ),
                  Factory<ScaleGestureRecognizer>(
                    () => ScaleGestureRecognizer(),
                  ),
                  Factory<TapGestureRecognizer>(
                    () => TapGestureRecognizer(),
                  ),
                  Factory<LongPressGestureRecognizer>(
                    () => LongPressGestureRecognizer(),
                  ),
                },
              ),
            ),
      
            // AppBar personalizada
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Botón cerrar
                      Material(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              LucideIcons.x,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Título
                      Expanded(
                        child: Text(
                          'Selecciona la ubicación en el mapa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      
            // Indicador de carga
            if (_isLoadingLocation && _userLocation == null)
              Positioned(
                top: 100,
                right: 16,
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
      
            // Panel inferior con botón confirmar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Coordenadas seleccionadas
                      if (_selectedCoordinates != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 16,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_selectedCoordinates!.lat.toStringAsFixed(6)}, ${_selectedCoordinates!.lng.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
      
                      // Botón confirmar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedCoordinates != null
                              ? () => Navigator.of(context).pop(_selectedCoordinates)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.check,
                                size: 20,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CONFIRMAR UBICACIÓN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
            ),
          ],
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

    // Cargar la imagen del marker personalizado
    try {
      final ByteData bytes = await rootBundle.load('assets/icons/lollipop-gps.png');
      final Uint8List list = bytes.buffer.asUint8List();
      
      final ui.Codec codec = await ui.instantiateImageCodec(list);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image; // Solo para extraer dimensiones
      
      await _mapboxMap!.style.addStyleImage(
        _markerImageId,
        12.0, // Scale aumentado a 12.0 para reducción extrema
        MbxImage(
          width: image.width,
          height: image.height,
          data: list, // Pasamos los bytes del PNG directo
        ),
        false, // sdf disabled
        [],
        [],
        null,
      );
      
      _isImageLoaded = true;
    } catch (e) {
      debugPrint('Error cargando imagen del marker: $e');
      _isImageLoaded = false;
    }

    // Crear annotation manager para markers
    _annotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();

    // Si hay posición inicial, mostrar marker
    if (widget.initialPosition != null) {
      _addMarker(widget.initialPosition!);
    }

    // Si obtuvimos ubicación del usuario, centrar ahí (solo si no hay posición inicial)
    if (_userLocation != null && widget.initialPosition == null) {
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
    final position = Position(coordinates.lng, coordinates.lat);

    if (!mounted) return;
    setState(() {
      _selectedCoordinates = position;
    });

    _addMarker(position);
  }

  Future<void> _addMarker(Position position) async {
    if (_annotationManager == null || !_isImageLoaded) return;

    // Remover marker anterior si existe
    if (_marker != null) {
      await _annotationManager!.delete(_marker!);
    }

    // Crear nuevo marker con icono personalizado
    _marker = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: position),
        iconImage: _markerImageId,
        iconSize: 0.5, // Reducido a 0.5
        iconAnchor: IconAnchor.BOTTOM, // Anclado en la parte inferior como un pin
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
