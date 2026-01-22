import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vector/features/home/presentation/widgets/active_route_card.dart';
import 'package:vector/features/home/presentation/widgets/home_action_buttons.dart';
import 'package:vector/features/home/presentation/widgets/home_header.dart';
import 'package:vector/features/home/presentation/widgets/home_stats_widget.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/packages/presentation/providers/jt_package_providers.dart';
import 'package:vector/features/packages/presentation/widgets/add_package_details_dialog.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/shared/presentation/screens/shared_scanner_screen.dart';
import 'package:vector/features/routes/presentation/widgets/add_route_dialog.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
      coordinates: mapbox.Position(0, 0),
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
                    builder: (context) => const AddRouteDialog(),
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

