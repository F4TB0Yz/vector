import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/packages/presentation/widgets/package_card.dart';
import 'package:vector/features/map/presentation/widgets/next_stop_card.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';


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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: Colors.red,
        ));
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: selectedRoute == null
            ? _NoRouteSelectedPlaceholder(
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
              child: Column(
                children: [
                   // Route Selector
                  Consumer(
                    builder: (context, ref, child) {
                      final routesAsync = ref.watch(routesProvider);
                      return routesAsync.when(
                        data: (routes) {
                          if (routes.isEmpty) return const SizedBox.shrink();
                          return _MapControlButton(
                            icon: LucideIcons.map,
                            isActive: selectedRoute != null,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: const Color(0xFF1E1E1E),
                                builder: (context) => ListView.builder(
                                  itemCount: routes.length,
                                  itemBuilder: (context, index) {
                                    final route = routes[index];
                                    return ListTile(
                                      title: Text(route.name, style: const TextStyle(color: Colors.white)),
                                      onTap: () {
                                        ref.read(selectedRouteProvider.notifier).state = route;
                                        Navigator.pop(context);
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const _MapControlButton(icon: LucideIcons.map, onTap: null),
                        error: (_, __) => const _MapControlButton(icon: LucideIcons.alertCircle, onTap: null, isActive: true),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: LucideIcons.layers,
                    onTap: () {
                       setState(() {
                          _showNextStopCard = !_showNextStopCard;
                          NavBarVisibilityNotification(!_showNextStopCard && !_showPackageList).dispatch(context);
                       });
                    },
                     isActive: _showNextStopCard,
                   ),
                   const SizedBox(height: 8),
                   _MapControlButton(
                     icon: LucideIcons.list,
                     onTap: () {
                       setState(() {
                          _showPackageList = !_showPackageList;
                          if (_showPackageList) {
                            _showNextStopCard = false;
                          }
                          NavBarVisibilityNotification(!_showPackageList).dispatch(context);
                       });
                     },
                     isActive: _showPackageList,
                   ),
                   const SizedBox(height: 8),
                   _MapControlButton(
                     icon: LucideIcons.crosshair,
                    onTap: () {
                      ref.read(mapProvider.notifier).centerOnUserLocation();
                    },
                  ),
                  const SizedBox(height: 8),
                   _MapControlButton(
                     icon: LucideIcons.plus,
                     onTap: () {
                        ref.read(mapProvider.notifier).zoomIn();
                     },
                   ),
                   const SizedBox(height: 8),
                   _MapControlButton(
                     icon: LucideIcons.minus,
                     onTap: () {
                        ref.read(mapProvider.notifier).zoomOut();
                     },
                   ),
                ],
              ),
            ),
        
            // 3. Tarjeta "Next Stop" (Overlay Inferior)
             AnimatedPositioned(
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeInOutBack,
               left: 0,
               right: 0,
               bottom: _showNextStopCard ? 30: -500,
               height: 350,
               child: PageView.builder(
                 controller: _pageController,
                 padEnds: false, 
                 itemCount: selectedRoute.stops.length, 
                 itemBuilder: (context, index) {
                   final stop = selectedRoute.stops[index];
                   
                   return AnimatedBuilder(
                     animation: _pageController,
                     builder: (context, child) {
                       double value = 0.0;
                       if (_pageController.position.haveDimensions) {
                         value = index.toDouble() - (_pageController.page ?? 0);
                         value = (value * 0.4).clamp(-1, 1);
                       }
                      
                       final scale = 1.0 - (value.abs() * 0.1);
                       final opacity = value.abs().clamp(0.0, 1.0);
        
                       return Center(
                         child: Transform.scale(
                           scale: scale,
                           child: Stack(
                             children: [
                               child!,
                               Positioned.fill(
                                 child: Container(
                                   margin: const EdgeInsets.all(16),
                                   decoration: BoxDecoration(
                                     color: Colors.black.withAlpha((255 * opacity * 1.3).clamp(0, 255).round()),
                                     borderRadius: BorderRadius.circular(4),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                       );
                     },
                     child: NextStopCard(
                       stopNumber: "PARADA ${stop.stopOrder}",
                       timeAway: "A ${3 + index * 5} MIN",
                       address: stop.address,
                       packageType: "Paquete",
                       weight: "N/A",
                       isPriority: index == 0,
                       note: null,
                       onClose: () {
                         setState(() {
                           _showNextStopCard = false;
                           const NavBarVisibilityNotification(true).dispatch(context);
                         });
                       },
                     ),
                   );
                 },
               ),
             ),
        
             // 4. Lista de Paquetes (Overlay Inferior)
             AnimatedPositioned(
               duration: const Duration(milliseconds: 300),
               curve: Curves.easeInOutBack,
               left: 0,
               right: 0,
               bottom: _showPackageList ? 0 : -600,
               height: 500,
               child: Container(
                 decoration: BoxDecoration(
                   color: const Color(0xFF1E1E1E).withAlpha(242),
                   borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                   border: Border(
                     top: BorderSide(color: Colors.white.withAlpha(25)),
                   ),
                   boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(127),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                   ]
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Header
                     Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(
                             "Paradas de ${selectedRoute.name}",
                             style: const TextStyle(
                               color: Colors.white,
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                           IconButton(
                             icon: const Icon(LucideIcons.x, color: Colors.grey),
                             onPressed: () {
                               setState(() {
                                 _showPackageList = false;
                                 const NavBarVisibilityNotification(true).dispatch(context);
                               });
                             },
                           )
                         ],
                       ),
                     ),
                     Divider(height: 1, color: Colors.white.withAlpha(25)),
                     
                     // Lista
                     Expanded(
                       child: ListView.separated(
                         padding: const EdgeInsets.all(16),
                         itemCount: selectedRoute.stops.length,
                         separatorBuilder: (context, index) => const SizedBox(height: 12),
                         itemBuilder: (context, index) {
                           final stop = selectedRoute.stops[index];
                            String statusInSpanish;
                            switch (stop.status) {
                              case StopStatus.pending:
                                statusInSpanish = 'PENDIENTE';
                                break;
                              case StopStatus.completed:
                                statusInSpanish = 'ENTREGADO';
                                break;
                              case StopStatus.failed:
                                statusInSpanish = 'FALLIDO';
                                break;
                              default:
                                statusInSpanish = 'DESCONOCIDO';
                            }
                           return PackageCard(
                              trackingId: stop.id,
                              status: statusInSpanish,
                              address: stop.address,
                              customerName: stop.name,
                              timeWindow: 'N/A',
                            );
                         }
                       ),
                     ),
                   ],
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}


class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;

  const _MapControlButton({
    required this.icon,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withAlpha(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.black : Colors.white,
            size: 24,
          ),
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
              Icon(
                LucideIcons.map,
                size: 80,
                color: Colors.grey[700],
              ),
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