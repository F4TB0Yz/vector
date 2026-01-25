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
  RouteEntity? _previousSelectedRoute;
  bool _previousIsOptimizing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    // Iniciar el proveedor de mapa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().init();
      context.read<MapProvider>().addListener(_onMapProviderChanged);
      context.read<RoutesProvider>().addListener(_onRoutesProviderChanged);
      // Initial check
      _onRoutesProviderChanged();
    });
  }

  @override
  void dispose() {
    context.read<MapProvider>().removeListener(_onMapProviderChanged);
    context.read<RoutesProvider>().removeListener(_onRoutesProviderChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onRoutesProviderChanged() {
    if (!mounted) return;
    final selectedRoute = context.read<RoutesProvider>().selectedRoute;

    if (selectedRoute?.id != _previousSelectedRoute?.id) {
      // Route changed
      if (selectedRoute != null) {
        context.read<MapProvider>().loadRouteById(selectedRoute.id);
      }
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return ConfirmAddStopDialog(request: nextRequest);
          },
        );
      } else if (nextRequest == null && _previousStopCreationRequest != null) {
        // Close Dialog
        Navigator.of(context, rootNavigator: true).pop();
      }
      _previousStopCreationRequest = nextRequest;
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    context.read<MapProvider>().onMapCreated(mapboxMap);
  }

  // Handles the long tap gesture on the map.
  void _onMapLongClick(MapContentGestureContext context) {
    final selectedRoute = this.context.read<RoutesProvider>().selectedRoute;
    if (selectedRoute == null) return;

    // Delegate the logic to the map provider
    // Note: 'context' here is MapContentGestureContext, avoiding conflict with BuildContext by implicit lookup or renaming if needed.
    // However, we need BuildContext to access provider.
    // The method argument shadows 'context'. Let's rename argument or use 'this.context'.
    this.context.read<MapProvider>().onMapLongClick(context.point);
  }

  void _onStopDelivered(StopEntity stop) {
    context.read<MapProvider>().updatePackageStatus(
      stop.package.id,
      PackageStatus.delivered,
    );
  }

  void _onStopFailed(StopEntity stop) {
    context.read<MapProvider>().updatePackageStatus(
      stop.package.id,
      PackageStatus.failed,
    );
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
                        onMapCreated: _onMapCreated,
                        onLongTapListener: _onMapLongClick,
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
