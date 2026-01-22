import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vector/features/home/presentation/widgets/floating_scan_button.dart';
import 'package:vector/features/packages/presentation/providers/filtered_stops_provider.dart';
import 'package:vector/features/packages/presentation/providers/packages_screen_notifier.dart';
import 'package:vector/features/packages/presentation/utils/stop_status_extension.dart';
import 'package:vector/features/packages/presentation/widgets/add_package_details_dialog.dart';
import 'package:vector/features/packages/presentation/widgets/filter_bar.dart';
import 'package:vector/features/packages/presentation/widgets/packages_header.dart';
import 'package:vector/features/packages/presentation/widgets/package_card.dart';
import 'package:vector/features/packages/presentation/widgets/route_date_warning_banner.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/shared/presentation/screens/shared_scanner_screen.dart';
import 'package:vector/shared/presentation/widgets/empty_state_widget.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  Future<void> _openScanner(BuildContext context) async {
    final selectedRoute = ref.read(selectedRouteProvider);
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
    final packagesScreenNotifier = ref.read(packagesScreenNotifierProvider.notifier);
    final prefillData = await packagesScreenNotifier.getPrefillData(code);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddPackageDetailsDialog(trackingCode: code, prefillData: prefillData),
    );

    if (result != null) {
      await packagesScreenNotifier.handleSavePackage(
        packageData: result,
        showAppToast: (message, {required type}) => showAppToast(context, message, type: type),
        onRouteNotSelected: () {
          showAppToast(context, 'Error: No hay ruta seleccionada para guardar.', type: ToastType.error);
        },
        onOptimisticUpdate: (updatedRoute) {
          ref.read(selectedRouteProvider.notifier).state = updatedRoute;
        },
        onRollback: (originalRoute) {
          ref.read(selectedRouteProvider.notifier).state = originalRoute;
        },
        onInvalidateRoutes: () {
          ref.invalidate(routesProvider);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoute = ref.watch(selectedRouteProvider);
    final filteredStops = ref.watch(filteredStopsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Neon Dark Theme Background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PackagesHeader(),
            const SizedBox(height: 16),
            const FilterBar(),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.1)),
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
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final stop = filteredStops[index];
                            return PackageCard(
                              trackingId: stop.id,
                              status: stop.status.toLocalizedString(),
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
        padding: EdgeInsets.only(bottom: 80.0),
        child: FloatingScanButton(onTap: () => _openScanner(context)),
      ),
    );
  }
}
