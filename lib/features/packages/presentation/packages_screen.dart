import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/home/presentation/widgets/floating_scan_button.dart';
import 'package:vector/features/packages/presentation/widgets/add_package_details_dialog.dart';
import 'package:vector/features/packages/presentation/widgets/filter_bar.dart';
import 'package:vector/features/packages/presentation/widgets/packages_header.dart';
import 'package:vector/features/packages/presentation/widgets/package_card.dart';
import 'package:vector/features/packages/presentation/widgets/package_card_compressed.dart';
import 'package:vector/features/packages/presentation/widgets/route_date_warning_banner.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/packages/presentation/providers/jt_package_providers.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import 'package:vector/shared/presentation/screens/shared_scanner_screen.dart';
import 'package:vector/shared/presentation/widgets/empty_state_widget.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/packages/domain/entities/manual_package_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/packages/presentation/helpers/coordinate_assignment_helpers.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  bool _isCompressedView = false;

  Future<void> _openScanner(BuildContext context) async {
    final selectedRoute = context.read<RoutesProvider>().selectedRoute;
    if (selectedRoute == null) {
      showAppToast(
        context,
        'Selecciona una ruta primero',
        type: ToastType.warning,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SharedScannerScreen(
          onDetect: (code) {
            Navigator.of(context).pop();
            _showDetailsDialog(context, code);
          },
        ),
      ),
    );
  }

  Future<void> _showDetailsDialog(BuildContext context, String code) async {
    final jtPackages = context.read<PackagesProvider>().packages;
    JTPackage? prefillData;
     try {
      prefillData = jtPackages.firstWhere((p) => p.waybillNo == code);
    } catch (_) {
      // Not found
    }

    if (!context.mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddPackageDetailsDialog(trackingCode: code, prefillData: prefillData),
    );

    if (!context.mounted) return;

    if (result != null) {
      _handleSavePackage(context, result);
    }
  }

  Future<void> _handleSavePackage(BuildContext context, Map<String, String> packageData) async {
    final routesProvider = context.read<RoutesProvider>();
    final selectedRoute = routesProvider.selectedRoute;
    final addStopUseCase = context.read<AddStopToRoute>();

    if (selectedRoute == null) {
      showAppToast(context, 'Error: No hay ruta seleccionada para guardar.', type: ToastType.error);
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
        coordinates: null, // Forward geocoding TODO
        updatedAt: DateTime.now(),
      ),
      stopOrder: _calculateNextStopOrder(selectedRoute.stops),
    );

    await routesProvider.addStop(stop, addStopUseCase);

    if (context.mounted) {
       if (routesProvider.error != null) {
         showAppToast(context, "Error: ${routesProvider.error}", type: ToastType.error);
       } else {
         showAppToast(context, "Paquete agregado", type: ToastType.success);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch routes provider for updates (selected route change, stops change, filter change)
    final routesProvider = context.watch<RoutesProvider>();
    final selectedRoute = routesProvider.selectedRoute;
    final filteredStops = routesProvider.filteredStops;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Neon Dark Theme Background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PackagesHeader(),
            if (selectedRoute != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Expanded(child: FilterBar()),
                    const SizedBox(width: 8),
                    _buildViewToggle(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.1)),
            const RouteDateWarningBanner(),
            Expanded(
              child: selectedRoute == null
                  ? const EmptyStateWidget(
                      icon: LucideIcons.map,
                      message: 'Selecciona una ruta',
                      subMessage: 'Usa el icono de mapa arriba a la derecha',
                    )
                  : filteredStops.isEmpty
                      ? const EmptyStateWidget(
                          icon: LucideIcons.package,
                          message: 'No hay paradas',
                          subMessage: 'Escanea paquetes para agregar',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filteredStops.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: _isCompressedView ? 8 : 12),
                          itemBuilder: (context, index) {
                            final stop = filteredStops[index];
                            return _isCompressedView
                                ? PackageCardCompressed(stop: stop)
                                : PackageCard(
                                    stop: stop,
                                    onAssignLocation: () => CoordinateAssignmentHelpers.openCoordinateAssignment(context),
                                    onDelivered: () {
                                      context.read<RoutesProvider>().updatePackageStatus(
                                            stop.package.id,
                                            PackageStatus.delivered,
                                          );
                                      showAppToast(
                                        context,
                                        'Paquete marcado como Entregado',
                                        type: ToastType.success,
                                      );
                                    },
                                    onFailed: () {
                                      context.read<RoutesProvider>().updatePackageStatus(
                                            stop.package.id,
                                            PackageStatus.failed,
                                          );
                                      showAppToast(
                                        context,
                                        'Paquete marcado como Fallido',
                                        type: ToastType.error,
                                      );
                                    },
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

  Widget _buildViewToggle() {
    return Container(
      height: 36, // Match FilterBar height roughly
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: () => setState(() => _isCompressedView = !_isCompressedView),
        icon: Icon(
          _isCompressedView ? LucideIcons.layoutList : LucideIcons.layoutGrid,
          color: _isCompressedView ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
          size: 18,
        ),
        tooltip: _isCompressedView ? 'Vista Detallada' : 'Vista Comprimida',
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
