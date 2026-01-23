import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/packages/presentation/providers/jt_package_providers.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';
import 'package:vector/features/packages/domain/entities/manual_package_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';

// State for PackagesScreen, can be expanded later
class PackagesScreenState {
  // No complex state for now, but ready for future expansion
  const PackagesScreenState();
}

final packagesScreenNotifierProvider = StateNotifierProvider<PackagesScreenNotifier, PackagesScreenState>((ref) {
  return PackagesScreenNotifier(ref);
});

class PackagesScreenNotifier extends StateNotifier<PackagesScreenState> {
  final Ref _ref;

  PackagesScreenNotifier(this._ref) : super(const PackagesScreenState());

  Future<JTPackage?> getPrefillData(String code) async {
    final jtPackages = _ref.read(jtPackagesProvider).asData?.value ?? [];
    try {
      return jtPackages.firstWhere((p) => p.waybillNo == code);
    } catch (_) {
      return null;
    }
  }

  Future<void> handleSavePackage({
    required Map<String, String> packageData,
    required Function(String message, {required ToastType type}) showAppToast,
    required Function() onRouteNotSelected,
    required Function(RouteEntity updatedRoute) onOptimisticUpdate,
    required Function(RouteEntity originalRoute) onRollback,
    required Function() onInvalidateRoutes,
  }) async {
    final selectedRoute = _ref.read(selectedRouteProvider);
    if (selectedRoute == null) {
      onRouteNotSelected();
      return;
    }

    final stop = StopEntity(
      id: packageData['code']!,
      package: ManualPackageEntity(
        id: packageData['code']!,
        receiverName: packageData['name']!,
        address: packageData['address']!,
        phone: packageData['phone']!,
        notes: packageData['notes'],
        status: PackageStatus.pending,
        coordinates: Position(0, 0),
        updatedAt: DateTime.now(),
      ),
      stopOrder: (selectedRoute.stops.length + 1),
    );

    // Optimistic Update
    final newStops = [...selectedRoute.stops, stop];
    final updatedRoute = selectedRoute.copyWith(stops: newStops);
    onOptimisticUpdate(updatedRoute);
    showAppToast("Paquete ${packageData['code']} agregado a ${selectedRoute.name}", type: ToastType.info);

    try {
      final useCase = _ref.read(addStopToRouteUseCaseProvider);
      await useCase(AddStopParams(routeId: selectedRoute.id, stop: stop));
      onInvalidateRoutes();
    } catch (e) {
      showAppToast("Error al guardar paquete: $e", type: ToastType.error);
      // Rollback
      onRollback(selectedRoute);
    }
  }
}
