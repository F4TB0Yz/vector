import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/map/presentation/widgets/map_controls_column.dart';
import 'package:vector/features/map/presentation/widgets/next_stop_page_view.dart';
import 'package:vector/features/map/presentation/widgets/package_list_overlay.dart';
import 'package:vector/features/map/presentation/widgets/no_route_selected_placeholder.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _showNextStopCard = false;
  bool _showPackageList = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);

    // Iniciar el proveedor de mapa
    Future.microtask(() => ref.read(mapProvider.notifier).init());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    ref.read(mapProvider.notifier).onMapCreated(mapboxMap);
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final selectedRoute = ref.watch(selectedRouteProvider);

    // Listen for changes in the globally selected route and command the map to update.
    ref.listen<RouteEntity?>(selectedRouteProvider, (previous, next) {
      // If the route is different from the one currently on the map, load it.
      if (next != null && next.id != mapState.activeRoute?.id) {
        ref.read(mapProvider.notifier).loadRouteById(next.id);
      }
    });

    // Listen for internal map errors.
    ref.listen<MapState>(mapProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        showAppToast(context, next.error!, type: ToastType.error);
      }
    });

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
                    // RepaintBoundary para optimización (Skill: Optimization)
                    child: RepaintBoundary(
                      child: MapWidget(
                        styleUri: MapboxStyles.DARK,
                        onMapCreated: _onMapCreated,
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
                      });
                    },
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
class _NoRouteSelectedPlaceholder extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onNavigateToRoutes;

  const _NoRouteSelectedPlaceholder({
    required this.isLoading,
    required this.onNavigateToRoutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3.0,
              )
            else ...[
              Icon(LucideIcons.map, size: 80, color: Colors.grey[700]),
              const SizedBox(height: 24),
              const Text(
                'No hay ruta seleccionada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Text(
                  'Selecciona una ruta usando el botón de arriba o desde la pantalla de Rutas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Botón para navegar a Rutas
              ElevatedButton.icon(
                onPressed: onNavigateToRoutes,
                icon: const Icon(LucideIcons.list, size: 20),
                label: const Text(
                  'Ver Mis Rutas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4), // Sharp corners
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
