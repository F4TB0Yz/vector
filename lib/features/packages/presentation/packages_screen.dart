import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/packages/presentation/widgets/package_card.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'providers/jt_package_providers.dart';

import 'package:vector/features/home/presentation/widgets/floating_scan_button.dart';
import 'package:vector/shared/presentation/widgets/smart_scanner/smart_scanner_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/packages/presentation/widgets/add_package_details_dialog.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';
import 'package:vector/shared/presentation/screens/shared_scanner_screen.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart'; // Required for addStop

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  int _selectedIndex = 0;

  final List<String> _filters = ["TODAS", "PENDIENTE", "ENTREGADO", "FALLIDO"];

  void _openScanner(BuildContext context) {
    final selectedRoute = ref.read(selectedRouteProvider);
    if (selectedRoute == null) {
      showAppToast(
        context,
        'Por favor selecciona una ruta primero.',
        type: ToastType.warning,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SharedScannerScreen(
          onDetect: (code) {
            Navigator.of(context).pop(); // Pop the scanner screen
            _showDetailsDialog(code);
          },
        ),
      ),
    );
  }

  Future<void> _showDetailsDialog(String code) async {
    final jtPackages = ref.read(jtPackagesProvider).asData?.value ?? [];
    JTPackage? prefillData;
    try {
      prefillData = jtPackages.firstWhere((p) => p.waybillNo == code);
    } catch (_) {
      // Package not found in J&T list, prefillData remains null
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) =>
          AddPackageDetailsDialog(trackingCode: code, prefillData: prefillData),
    );

    if (result != null) {
      _handleSavePackage(result);
    }
  }

  Future<void> _handleSavePackage(Map<String, String> packageData) async {
    final selectedRoute = ref.read(selectedRouteProvider);
    if (selectedRoute == null) {
      if (mounted) {
        showAppToast(
          context,
          'Error: No hay ruta seleccionada para guardar.',
          type: ToastType.error,
        );
      }
      return;
    }

    final stop = StopEntity(
      id: packageData['code']!,
      name: packageData['name']!,
      address: packageData['address']!,
      // TODO: Add Geocoding from address
      coordinates: Position(0, 0),
      status: StopStatus.pending,
      stopOrder: (selectedRoute.stops.length + 1),
    );

    // --- 1. Optimistic UI Update ---
    final newStops = [...selectedRoute.stops, stop];
    final optimisticallyUpdatedRoute = RouteEntity(
      id: selectedRoute.id,
      name: selectedRoute.name,
      date: selectedRoute.date,
      progress: selectedRoute.progress,
      createdAt: selectedRoute.createdAt,
      updatedAt: selectedRoute.updatedAt,
      stops: newStops,
    );

    ref.read(selectedRouteProvider.notifier).state = optimisticallyUpdatedRoute;

    if (mounted) {
      showAppToast(
        context,
        "Paquete ${packageData['code']} agregado a ${selectedRoute.name}",
        type: ToastType.info,
      );
    }

    // --- 2. Background Persistence ---
    try {
      final useCase = ref.read(addStopToRouteUseCaseProvider);
      await useCase(AddStopParams(routeId: selectedRoute.id, stop: stop));

      ref.invalidate(routesProvider);
    } catch (e) {
      // --- 3. Rollback on Error ---
      if (mounted) {
        showAppToast(
          context,
          "Error al guardar paquete: $e",
          type: ToastType.error,
        );
      }
      ref.read(selectedRouteProvider.notifier).state = selectedRoute;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Correctly watch the providers.
    final selectedRoute = ref.watch(selectedRouteProvider);
    final stops = ref.watch(routeStopsProvider);

    // --- DEBUGGING ---
    debugPrint("--- Building PackagesScreen ---");
    if (selectedRoute != null) {
      debugPrint("Selected route: ${selectedRoute.name}");
      debugPrint("Stops from routeStopsProvider: ${stops.length}");
    } else {
      debugPrint("No route selected.");
    }
    // --- /DEBUGGING ---

    // Filter stops based on the selected chip
    final filteredStops = stops.where((stop) {
      switch (_filters[_selectedIndex]) {
        case 'PENDIENTE':
          return stop.status == StopStatus.pending;
        case 'ENTREGADO':
          return stop.status == StopStatus.completed;
        case 'FALLIDO':
          return stop.status == StopStatus.failed;
        case 'TODAS':
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paradas de la Ruta',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedRoute?.name ?? 'Ninguna ruta seleccionada',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Route Selector
                      Consumer(
                        builder: (context, ref, child) {
                          final routesAsync = ref.watch(routesProvider);
                          final selectedRoute = ref.watch(
                            selectedRouteProvider,
                          );

                          return routesAsync.when(
                            data: (routes) {
                              if (routes.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return PopupMenuButton<RouteEntity>(
                                tooltip:
                                    selectedRoute?.name ?? 'Seleccionar Ruta',
                                icon: Icon(
                                  LucideIcons.map,
                                  color: selectedRoute != null
                                      ? AppColors.primary
                                      : Colors.grey,
                                ),
                                color: const Color(0xFF2C2C35),
                                onSelected: (route) {
                                  ref
                                          .read(selectedRouteProvider.notifier)
                                          .state =
                                      route;
                                  showAppToast(
                                    context,
                                    'Ruta seleccionada: ${route.name}',
                                    type: ToastType.success,
                                    duration: const Duration(seconds: 1),
                                  );
                                },
                                itemBuilder: (context) => routes.map((route) {
                                  return PopupMenuItem<RouteEntity>(
                                    value: route,
                                    child: Text(
                                      route.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const SizedBox(
                              width: 48,
                            ), // Placeholder for icon button size
                            error: (_, __) => const Icon(
                              LucideIcons.alertCircle,
                              color: Colors.red,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Importar Paquetes de J&T',
                        onPressed: () {
                          ref
                              .read(jtPackagesProvider.notifier)
                              .importPackages();
                          showAppToast(
                            context,
                            'Importando paquetes de J&T en segundo plano...',
                            type: ToastType.success,
                          );
                        },
                        icon: const Icon(
                          LucideIcons.downloadCloud,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Selectors
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF2C2C35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.white.withAlpha(25),
                          ),
                        ),
                        child: Text(
                          _filters[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Colors.white.withAlpha(25)),

            Expanded(
              child: selectedRoute == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.map,
                            size: 64,
                            color: Colors.grey[800],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Selecciona una ruta en la pantalla anterior',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : filteredStops.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.package,
                            size: 64,
                            color: Colors.grey[800],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay paradas en esta ruta',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Puedes escanear paquetes para agregarlos',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        top: 16.0,
                        bottom: 100.0,
                      ),
                      itemCount: filteredStops.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final stop = filteredStops[index];

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
                        }

                        return PackageCard(
                          trackingId: stop.id,
                          status: statusInSpanish,
                          address: stop.address,
                          customerName: stop.name,
                          timeWindow: 'N/A', // This info is not in StopEntity
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingScanButton(onTap: () => _openScanner(context)),
      ),
    );
  }
}
