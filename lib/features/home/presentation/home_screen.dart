import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector/core/di/injection_container.dart' as di;
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import 'package:vector/features/home/presentation/providers/home_provider.dart';

import 'package:vector/features/home/presentation/widgets/active_route_card.dart';
import 'package:vector/features/home/presentation/widgets/home_action_buttons.dart';
import 'package:vector/features/home/presentation/widgets/home_header.dart';
import 'package:vector/features/home/presentation/widgets/home_stats_widget.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/packages/presentation/providers/jt_package_providers.dart';
import 'package:vector/features/packages/presentation/widgets/add_package_details_dialog.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/shared/presentation/screens/shared_scanner_screen.dart';
import 'package:vector/features/routes/presentation/widgets/add_route_dialog.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';
import 'package:vector/features/packages/domain/entities/manual_package_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/core/database/widgets/stop_order_migration_dialog.dart';
import 'package:vector/core/database/providers/migration_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          HomeProvider(addStopToRouteUseCase: di.sl<AddStopToRoute>()),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreenContent> {
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
      stopOrder: _calculateNextStopOrder(selectedRoute.stops),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 120, // Espacio para la FloatingNavBar
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HomeHeader es estático, no necesita RepaintBoundary
          const HomeHeader(),

          const SizedBox(height: 24),

          // ActiveRouteCard - RepaintBoundary removido para reducir overhead inicial
          //const ActiveRouteCard(),
          const SizedBox(height: 20),

          // HomeStatsWidget es estático, no necesita RepaintBoundary
          //const HomeStatsWidget(),
          const SizedBox(height: 20),

          // HomeActionButtons(
          //   onScanTap: () => _openScanner(context),
          //   onNewRouteTap: () {
          //     showDialog(
          //       context: context,
          //       builder: (dialogContext) => ChangeNotifierProvider.value(
          //         value: context.read<RoutesProvider>(),
          //         child: const AddRouteDialog(),
          //       ),
          //     );
          //   },
          // ),
          const SizedBox(height: 20),

          // TODO: TEMPORAL - Botón para ejecutar migración de stopOrder
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => ChangeNotifierProvider.value(
                    value: context.read<MigrationProvider>(),
                    child: const StopOrderMigrationDialog(),
                  ),
                );
              },
              icon: const Icon(Icons.build, size: 18),
              label: const Text('Reparar Orden de Paradas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula el siguiente stopOrder basado en el máximo valor actual.
  /// Esto previene problemas con valores desordenados.
  int _calculateNextStopOrder(List<StopEntity> stops) {
    if (stops.isEmpty) return 1;
    return stops.map((s) => s.stopOrder).reduce(max) + 1;
  }
}
