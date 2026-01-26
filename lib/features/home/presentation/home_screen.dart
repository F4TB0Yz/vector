import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector/features/home/presentation/providers/home_provider.dart';

import 'package:vector/features/home/presentation/widgets/active_route_card.dart';
import 'package:vector/features/home/presentation/widgets/home_action_buttons.dart';
import 'package:vector/features/home/presentation/widgets/home_header.dart';
import 'package:vector/features/home/presentation/widgets/home_stats_widget.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/packages/presentation/providers/jt_package_providers.dart';
import 'package:vector/features/packages/presentation/widgets/add_package_details_dialog.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
// import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart'; // Removed
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/shared/presentation/screens/shared_scanner_screen.dart';
import 'package:vector/features/routes/presentation/widgets/add_route_dialog.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';
import 'package:vector/features/packages/domain/entities/manual_package_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _openScanner(BuildContext context) {
    final selectedRoute = context.read<RoutesProvider>().selectedRoute;
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
    final jtPackages = context.read<PackagesProvider>().packages;
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
    final routesProvider = context.read<RoutesProvider>();
    final selectedRoute = routesProvider.selectedRoute;
    
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
      routeId: selectedRoute.id,
      package: ManualPackageEntity(
        id: packageData['code']!,
        receiverName: packageData['name']!,
        address: packageData['address']!,
        phone: packageData['phone']!,
        notes: packageData['notes'],
        status: PackageStatus.pending,
        coordinates:
            null, // TODO: Implement forward geocoding (address → coordinates)
        updatedAt: DateTime.now(),
      ),
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

    // Update RoutesProvider state locally for immediate feedback
    // Note: RoutesProvider.selectRoute updates the selected route.
    // However, to update the route in the LIST, we might need a method in RoutesProvider.
    // For now, updating selectedRoute is enough for UI.
    routesProvider.selectRoute(optimisticallyUpdatedRoute);

    if (mounted) {
      showAppToast(
        context,
        "Paquete ${packageData['code']} agregado a ${selectedRoute.name}",
        type: ToastType.info,
      );
    }

    // --- 2. Background Persistence via HomeProvider ---
    try {
      await context.read<HomeProvider>().savePackageToRoute(
            routeId: selectedRoute.id,
            stop: stop,
          );

      // Invalidate/Refresh routes
      if (mounted) {
         context.read<RoutesProvider>().loadRoutes();
      }
    } catch (e) {
      // --- 3. Rollback on Error ---
      if (mounted) {
        showAppToast(
          context,
          "Error al guardar paquete: $e",
          type: ToastType.error,
        );
         context.read<RoutesProvider>().selectRoute(selectedRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom:
            false, // Permitir que el contenido fluya detrás de la navbar si es necesario, pero usaremos padding
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 120, // Espacio para la FloatingNavBar
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),

              const SizedBox(height: 24),

              ActiveRouteCard(deliveredCount: 12, totalCount: 45),

              const SizedBox(height: 20),

              const HomeStatsWidget(deliveredCount: 12),

              const SizedBox(height: 20),

              HomeActionButtons(
                onScanTap: () => _openScanner(context),
                onNewRouteTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => Provider.value(
                      value: context.read<RoutesProvider>(),
                      child: const AddRouteDialog(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
