import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/packages/presentation/widgets/package_card.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'providers/jt_package_providers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vector/features/home/presentation/widgets/floating_scan_button.dart';
import 'package:vector/shared/presentation/widgets/smart_scanner/smart_scanner_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una ruta primero desde la pantalla de Rutas.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              SmartScannerWidget(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _handleScan(barcode.rawValue!);
                      Navigator.of(context).pop();
                      break;
                    }
                  }
                },
              ),
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleScan(String code) async {
    final selectedRoute = ref.read(selectedRouteProvider);
    if (selectedRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una ruta primero'), backgroundColor: Colors.orange),
      );
      return;
    }

    final stop = StopEntity(
      id: code,
      name: "Paquete $code",
      address: "Dirección desconocida (escaneado)",
      coordinates: Position(0, 0),
      status: StopStatus.pending,
      stopOrder: (selectedRoute.stops.length + 1),
    );

    debugPrint("--- Handling Scan ---");
    debugPrint("1. Route '${selectedRoute.name}' has ${selectedRoute.stops.length} stops before adding.");
    debugPrint("2. Adding stop: ${stop.id} to database...");

    try {
      final useCase = ref.read(addStopToRouteUseCaseProvider);
      await useCase(AddStopParams(routeId: selectedRoute.id, stop: stop));
      debugPrint("3. Stop added to DB successfully.");

      // --- CORRECT REFRESH LOGIC ---
      debugPrint("4. Invalidating routesProvider to force refresh.");
      ref.invalidate(routesProvider);

      debugPrint("5. Waiting for routesProvider to rebuild...");
      final newRoutesList = await ref.read(routesProvider.future);
      debugPrint("6. routesProvider rebuilt. Total routes fetched: ${newRoutesList.length}");

      final matches = newRoutesList.where((route) => route.id == selectedRoute.id);
      final updatedRoute = matches.isNotEmpty ? matches.first : null;
      
      if (updatedRoute != null) {
        debugPrint("7. Found updated route. Stops count: ${updatedRoute.stops.length}.");
        ref.read(selectedRouteProvider.notifier).state = updatedRoute;
        debugPrint("8. selectedRouteProvider has been updated. UI should refresh.");
      } else {
        debugPrint("[ERROR] Could not find the updated route after refresh.");
      }
      
      if (mounted) {
        _showToast("Paquete $code agregado a ${selectedRoute.name}");
      }
    } catch (e) {
      debugPrint("[ERROR] Failed to add stop: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al agregar paquete: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showToast(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          // Make sure the dialog is still mounted before trying to pop
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        });
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Correctly watch the providers.
    final selectedRoute = ref.watch(selectedRouteProvider);
    final stops = ref.watch(routeStopsProvider);

    // --- DEBUGGING ---
    debugPrint("--- Building PackagesScreen ---");
    if(selectedRoute != null) {
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
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paradas de la Ruta',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedRoute?.name ?? 'Ninguna ruta seleccionada',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Importar Paquetes de J&T',
                    onPressed: () {
                      ref.read(jtPackagesProvider.notifier).importPackages();
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Importando paquetes de J&T en segundo plano...'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    icon: const Icon(
                      LucideIcons.downloadCloud,
                      color: Colors.white,
                    ),
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
                          color: isSelected ? AppColors.primary : const Color(0xFF2C2C35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
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
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withOpacity(0.1),
            ),
            
            Expanded(
              child: selectedRoute == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.map, size: 64, color: Colors.grey[800]),
                          const SizedBox(height: 16),
                          Text(
                            'Selecciona una ruta en la pantalla anterior',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[400], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : filteredStops.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.package, size: 64, color: Colors.grey[800]),
                              const SizedBox(height: 16),
                              Text(
                                'No hay paradas en esta ruta',
                                style: TextStyle(color: Colors.grey[400], fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Puedes escanear paquetes para agregarlos',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final stop = filteredStops[index];
                            final statusString = stop.status.toString().split('.').last.toUpperCase();

                            return PackageCard(
                              trackingId: stop.id,
                              status: statusString,
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
        child: FloatingScanButton(
          onTap: () => _openScanner(context),
        ),
      ),
    );
  }
}
