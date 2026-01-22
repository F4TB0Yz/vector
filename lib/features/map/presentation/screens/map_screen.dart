// The file map_screen.dart is not being used as per the user's request.
// This is being done because the user asked to delete it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/packages/presentation/widgets/package_card.dart';
import 'package:vector/features/map/presentation/widgets/next_stop_card.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart';

class MapScreen extends ConsumerStatefulWidget { // Changed to ConsumerStatefulWidget
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

    // Escuchar cambios en el provider para mostrar errores.
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
        child: mapState.activeRoute == null
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
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Column(
                children: [
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
                 itemCount: 3, 
                 itemBuilder: (context, index) {
                   final stopNum = index + 4;
                   
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
                                     color: Colors.black.withValues(alpha: opacity * 1.3),
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
                       stopNumber: "PARADA 0$stopNum",
                       timeAway: "A ${3 + index * 5} MIN",
                       address: index == 0 
                           ? "482 Industrial Pkwy, Unit B"
                           : "Calle ${10 + index} #45-30, Centro",
                       packageType: index == 1 ? "Caja Grande" : "Caja Pequeña",
                       weight: "${2.5 + index}kg",
                       isPriority: index == 0,
                       note: index == 0 ? "Nota: Dejar en recepción. Cód: 4821." : null,
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
                   color: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
                   borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                   border: Border(
                     top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                   ),
                   boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
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
                           const Text(
                             "Lista de Paquetes",
                             style: TextStyle(
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
                     Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                     
                     // Lista
                     Expanded(
                       child: ListView(
                         padding: const EdgeInsets.all(16),
                         children: const [
                            PackageCard(
                              trackingId: 'VEC-8821',
                              status: 'PENDIENTE',
                              address: '482 Industrial Pkwy, Unit B',
                              customerName: 'Juan Pérez',
                              timeWindow: 'Hoy, 2:00 PM - 4:00 PM',
                            ),
                            SizedBox(height: 12),
                            PackageCard(
                              trackingId: 'VEC-8825',
                              status: 'PENDIENTE',
                              address: 'Calle 10 #45-30, Centro',
                              customerName: 'Maria Suarez',
                              timeWindow: 'Hoy, 2:30 PM - 4:30 PM',
                            ),
                            SizedBox(height: 12),
                            PackageCard(
                              trackingId: 'VEC-8828',
                              status: 'PENDIENTE',
                              address: 'Av. Las Palmas #20-10',
                              customerName: 'Carlos Ruiz',
                              timeWindow: 'Hoy, 3:00 PM - 5:00 PM',
                            ),
                            SizedBox(height: 80),
                         ],
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
  final VoidCallback onTap;
  final bool isActive;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
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
              color: Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
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
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3.0,
              )
            else ...[
              Icon(
                LucideIcons.mapPin,
                size: 80,
                color: Colors.grey[700],
              ),
              const SizedBox(height: 24),
              const Text(
                'No hay ruta activa',
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
                  'Selecciona una ruta desde la pantalla de Rutas para visualizarla en el mapa.',
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
                icon: const Icon(LucideIcons.map, size: 20),
                label: const Text(
                  'Ver Rutas Disponibles',
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