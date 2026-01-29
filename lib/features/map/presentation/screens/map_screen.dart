import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';
import 'package:vector/features/map/presentation/providers/map_state.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/map/presentation/widgets/map_controls_column.dart';
import 'package:vector/features/map/presentation/widgets/next_stop_page_view.dart';
import 'package:vector/features/map/presentation/widgets/package_list_overlay.dart';
import 'package:vector/features/map/presentation/widgets/no_route_selected_placeholder.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/map/presentation/widgets/confirm_add_stop_dialog.dart';
import 'package:vector/features/map/presentation/widgets/package_details_dialog.dart';

class MapScreen extends StatefulWidget {

  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _showNextStopCard = false;
  bool _showPackageList = false;
  late PageController _pageController;

  // Track previous state for side effects
  String? _previousError;
  StopCreationRequest? _previousStopCreationRequest;
  StopEntity? _previousSelectedStop;
  RouteEntity? _previousSelectedRoute;
  bool _previousIsOptimizing = false;

  bool _isStopDialogShowing = false;
  bool _isPackageDialogShowing = false;


  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    // Iniciar el proveedor de mapa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MapProvider>().init();
      context.read<MapProvider>().addListener(_onMapProviderChanged);
      context.read<RoutesProvider>().addListener(_onRoutesProviderChanged);
      // Initial check
      _onRoutesProviderChanged();
    });
  }

  @override
  void dispose() {
    // Es posible que el contexto ya no sea válido aquí si el widget se desmonta
    // pero guardamos referencia previa para limpiar listeners correctamente si es posible
    // Sin embargo, en dispose usualmente usamos el contexto del widget.
    // Una mejor práctica es guardar los providers en variables en initState.
    // Por simplicidad en este fix:
    try {
      context.read<MapProvider>().removeListener(_onMapProviderChanged);
      context.read<RoutesProvider>().removeListener(_onRoutesProviderChanged);
    } catch (_) {}
    
    _pageController.dispose();
    super.dispose();
  }

  void _onRoutesProviderChanged() {
    if (!mounted) return;
    final routesProvider = context.read<RoutesProvider>();
    final selectedRoute = routesProvider.selectedRoute;

    // 1. Handle Route Switching
    if (selectedRoute?.id != _previousSelectedRoute?.id) {
      if (selectedRoute != null) {
        context.read<MapProvider>().loadRouteById(selectedRoute.id);
      }
      _previousSelectedRoute = selectedRoute;
      return; 
    }

    // 2. Handle Same Route Updates (e.g. status changes from Package List)
    // If the route object instance has changed but ID is same, sync it to map.
    if (selectedRoute != null && selectedRoute != _previousSelectedRoute) {
      context.read<MapProvider>().syncRoute(selectedRoute);
      _previousSelectedRoute = selectedRoute;
    }
  }

  void _onMapProviderChanged() {
    if (!mounted) return;
    final mapState = context.read<MapProvider>().state;

    // Error Handling
    if (mapState.error != null && mapState.error != _previousError) {
      showAppToast(context, mapState.error!, type: ToastType.error);
    }
    _previousError = mapState.error;

    // Optimization Feedback
    if (mapState.isOptimizing && !_previousIsOptimizing) {
      showAppToast(context, 'Optimizando ruta...', type: ToastType.info);
    } else if (!mapState.isOptimizing &&
        _previousIsOptimizing &&
        mapState.error == null) {
      showAppToast(
        context,
        '¡Ruta optimizada con éxito!',
        type: ToastType.success,
      );
    }
    _previousIsOptimizing = mapState.isOptimizing;

    // Stop Creation Dialog
    final nextRequest = mapState.stopCreationRequest;
    if (nextRequest != _previousStopCreationRequest) {
      if (nextRequest != null && _previousStopCreationRequest == null) {
        // Open Dialog
        _isStopDialogShowing = true;
        final mapProvider = context.read<MapProvider>();
        final routesProvider = context.read<RoutesProvider>();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: mapProvider),
                ChangeNotifierProvider.value(value: routesProvider),
              ],
              child: ConfirmAddStopDialog(request: nextRequest),
            );
          },
        ).then((_) => _isStopDialogShowing = false);
      } else if (nextRequest == null &&
          _previousStopCreationRequest != null &&
          _isStopDialogShowing) {
        // Close Dialog programmatically only if it's still showing
        Navigator.of(context, rootNavigator: true).pop();
        _isStopDialogShowing = false;
      }
      _previousStopCreationRequest = nextRequest;
    }

    // Package Details Dialog
    final selectedStop = mapState.selectedStop;
    if (selectedStop != _previousSelectedStop) {
      if (selectedStop != null && _previousSelectedStop == null) {
        _isPackageDialogShowing = true;
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return PackageDetailsDialog(stop: selectedStop);
          },
        ).then((_) {
          _isPackageDialogShowing = false;
          // When dialog is closed by user (tap outside or close button),
          // clear the selection in the provider.
          if (mounted) {
            context.read<MapProvider>().clearSelectedStop();
          }
        });
      } else if (selectedStop == null &&
          _previousSelectedStop != null &&
          _isPackageDialogShowing) {
        // If state cleared externally, close dialog programmatically
        Navigator.of(context, rootNavigator: true).pop();
        _isPackageDialogShowing = false;
      }
      _previousSelectedStop = selectedStop;
    }

  }

  void _onMapCreated(MapboxMap mapboxMap) {
    context.read<MapProvider>().onMapCreated(mapboxMap);
  }

  // Handles the tap gesture on the map.
  void _onMapTap(MapContentGestureContext context) {
    this.context.read<MapProvider>().onMapTap(context.touchPosition);
  }


  // Handles the long tap gesture on the map.
  void _onMapLongClick(MapContentGestureContext context) {
    final selectedRoute = this.context.read<RoutesProvider>().selectedRoute;
    if (selectedRoute == null) return;
    this.context.read<MapProvider>().onMapLongClick(context.point);
  }

  void _onStopDelivered(StopEntity stop) {
    // 1. Update in DB and List State (Single Source of Truth)
    context.read<RoutesProvider>().updatePackageStatus(
          stop.package.id,
          PackageStatus.delivered,
        );
    
    // 2. MapProvider listens to RoutesProvider via _onRoutesProviderChanged,
    // but we also want immediate visual feedback on the map markers.
    context.read<MapProvider>().updatePackageStatus(
          stop.package.id,
          PackageStatus.delivered,
        );
        
    showAppToast(context, 'Entregado', type: ToastType.success);
  }

  void _onStopFailed(StopEntity stop) {
    // 1. Update in DB and List State
    context.read<RoutesProvider>().updatePackageStatus(
          stop.package.id,
          PackageStatus.failed,
        );

    // 2. Update Map Visuals
    context.read<MapProvider>().updatePackageStatus(
          stop.package.id,
          PackageStatus.failed,
        );
        
    showAppToast(context, 'Fallido', type: ToastType.error);
  }

  @override
  Widget build(BuildContext context) {
    final mapState = context.watch<MapProvider>().state;
    final selectedRoute = context.watch<RoutesProvider>().selectedRoute;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: selectedRoute == null
            ? NoRouteSelectedPlaceholder(
                isLoading: mapState.isLoadingRoute,
                onNavigateToRoutes: () {
                  const ChangeTabNotification(1).dispatch(context);
                },
              )
            : Stack(
                children: [
                  // 1. Capa de Mapa Real
                  Positioned.fill(
                    child: RepaintBoundary(
                        child: MapWidget(
                          cameraOptions: CameraOptions(
                            center: Point(
                              coordinates: Position(-74.3638, 4.3361),
                            ),
                            zoom: 12.0,
                          ),
                          onMapCreated: _onMapCreated,
                          onTapListener: _onMapTap,
                          onLongTapListener: _onMapLongClick,
                          onCameraChangeListener: (_) {
                            context.read<MapProvider>().disableFollowMode();
                          },
                        styleUri: MapboxStyles.DARK,
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>{
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
                  ),

                  // 2. Botones de Control (Derecha Superior)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: MapControlsColumn(
                      showNextStopCard: _showNextStopCard,
                      showPackageList: _showPackageList,
                      onToggleNextStopCard: () {
                        setState(() {
                          _showNextStopCard = !_showNextStopCard;
                          NavBarVisibilityNotification(
                            !_showNextStopCard && !_showPackageList,
                          ).dispatch(context);
                        });
                      },
                      onTogglePackageList: () {
                        setState(() {
                          _showPackageList = !_showPackageList;
                          if (_showPackageList) {
                            _showNextStopCard = false;
                          }
                          NavBarVisibilityNotification(
                            !_showPackageList,
                          ).dispatch(context);
                        });
                      },
                    ),
                  ),

                  // 3. Tarjeta "Next Stop" (Overlay Inferior)
                  NextStopPageView(
                    pageController: _pageController,
                    selectedRoute: selectedRoute,
                    showNextStopCard: _showNextStopCard,
                    onCloseNextStopCard: () {
                      setState(() {
                        _showNextStopCard = false;
                        NavBarVisibilityNotification(true).dispatch(context);
                      });
                    },
                    onDelivered: _onStopDelivered,
                    onFailed: _onStopFailed,
                  ),

                  // 4. Lista de Paquetes (Overlay Inferior)
                  PackageListOverlay(
                    selectedRoute: selectedRoute,
                    showPackageList: _showPackageList,
                    onClosePackageList: () {
                      setState(() {
                        _showPackageList = false;
                      });
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
