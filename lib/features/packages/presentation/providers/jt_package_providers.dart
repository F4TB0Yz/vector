import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vector/features/packages/data/datasources/jt_packages_datasource.dart';
import 'package:vector/features/packages/data/repositories/jt_package_repository_impl.dart';
import 'package:vector/features/packages/domain/repositories/jt_package_repository.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/auth/presentation/providers/auth_provider.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';

// --- Dependencies ---

final jtPackagesDataSourceProvider = Provider<JTPackagesDataSource>((ref) {
  // We can reuse the same Dio instance from Auth, or create a new one.
  // Reusing is better for connection pooling if configured.
  return JTPackagesDataSourceImpl(ref.watch(dioProvider));
});

final jtPackageRepositoryProvider = Provider<JTPackageRepository>((ref) {
  return JTPackageRepositoryImpl(
    ref.watch(jtPackagesDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  );
});

// --- State ---

final jtPackagesProvider =
    AsyncNotifierProvider<JTPackagesNotifier, List<JTPackage>>(
      JTPackagesNotifier.new,
    );

class JTPackagesNotifier extends AsyncNotifier<List<JTPackage>> {
  @override
  FutureOr<List<JTPackage>> build() {
    return [];
  }

  Future<void> importPackages() async {
    state = const AsyncValue.loading();
    final repository = ref.read(jtPackageRepositoryProvider);
    final result = await repository.getJTPackages();

    await result.fold(
      (failure) async {
        if (failure.message.contains('Sesión expirada') ||
            failure.message.contains('135010037')) {
          ref.read(authProvider.notifier).logout();
        }
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (packages) async {
        state = AsyncValue.data(packages);

        // Intentar guardar los paquetes en la ruta seleccionada
        await _savePackagesToSelectedRoute(packages);
      },
    );
  }

  /// Architecture: Separated business logic - Save packages to currently selected route
  ///
  /// This method handles the persistence of imported packages to the database.
  /// It validates that a route is selected before attempting to save.
  ///
  /// Returns the number of successfully saved packages.
  Future<int> _savePackagesToSelectedRoute(List<JTPackage> packages) async {
    final selectedRoute = ref.read(selectedRouteProvider);
    if (selectedRoute == null) {
      // ignore: avoid_print
      print(
        '[JTPackages] ⚠️ No route selected. Packages imported but not saved to route.',
      );
      return 0;
    }

    // ignore: avoid_print
    print(
      '[JTPackages] 💾 Saving ${packages.length} packages to route ${selectedRoute.name}...',
    );

    int savedCount = 0;
    int errorCount = 0;
    final addStopUseCase = ref.read(addStopToRouteUseCaseProvider);

    // Optimization: Process packages sequentially to avoid overwhelming the database
    for (final package in packages) {
      final result = await _savePackageAsStop(
        package: package,
        selectedRoute: selectedRoute,
        stopOrder: selectedRoute.stops.length + savedCount + 1,
        addStopUseCase: addStopUseCase,
      );

      if (result) {
        savedCount++;
      } else {
        errorCount++;
      }
    }

    // ignore: avoid_print
    print('[JTPackages] ✅ Saved $savedCount packages, $errorCount errors');

    // Architecture: Refresh state after batch operation
    await _refreshRouteState(selectedRoute.id);

    return savedCount;
  }

  /// Architecture: Extract single package save operation for clarity
  Future<bool> _savePackageAsStop({
    required JTPackage package,
    required dynamic selectedRoute,
    required int stopOrder,
    required AddStopToRoute addStopUseCase,
  }) async {
    try {
      final stop = StopEntity(
        id: package.waybillNo,
        routeId: selectedRoute.id,
        package: package,
        stopOrder: stopOrder,
      );

      final result = await addStopUseCase(
        AddStopParams(routeId: selectedRoute.id, stop: stop),
      );

      return result.fold((failure) {
        // ignore: avoid_print
        print(
          '[JTPackages] ❌ Error saving ${package.waybillNo}: ${failure.message}',
        );
        return false;
      }, (_) => true);
    } catch (e) {
      // ignore: avoid_print
      print('[JTPackages] ❌ Exception saving ${package.waybillNo}: $e');
      return false;
    }
  }

  /// Architecture: Extract route refresh logic for reusability
  Future<void> _refreshRouteState(String routeId) async {
    // Invalidate routes to trigger database fetch
    ref.invalidate(routesProvider);

    // Optimization: Small delay to ensure database commit completes
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final updatedRoutes = await ref.read(routesProvider.future);
      final updatedRoute = updatedRoutes.firstWhere(
        (route) => route.id == routeId,
      );

      ref.read(selectedRouteProvider.notifier).state = updatedRoute;

      // ignore: avoid_print
      print(
        '[JTPackages] 🔄 Route updated with ${updatedRoute.stops.length} total stops',
      );
    } catch (e) {
      // ignore: avoid_print
      print(
        '[JTPackages] ⚠️ Could not refresh route, keeping current state: $e',
      );
    }
  }
}

// --- DERIVED STATE ---

// Provides the list of stops for the currently selected route.
final routeStopsProvider = Provider<List<StopEntity>>((ref) {
  final selectedRoute = ref.watch(selectedRouteProvider);
  // Return the stops of the selected route, or an empty list if no route is selected.
  // The list is sorted by the 'stopOrder' property.
  if (selectedRoute == null) return [];

  // Create a copy to sort safely without mutating original state
  final stops = List<StopEntity>.from(selectedRoute.stops);
  stops.sort((a, b) => a.stopOrder.compareTo(b.stopOrder));
  return stops;
});
