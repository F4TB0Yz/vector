import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/packages/domain/repositories/jt_package_repository.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';

class PackagesProvider extends ChangeNotifier {
  final JTPackageRepository _repository;

  // State
  List<JTPackage> _packages = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<JTPackage> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PackagesProvider({
    required JTPackageRepository repository,
  }) : _repository = repository;

  Future<void> importPackages({
    required RouteEntity? selectedRoute,
    required AddStopToRoute addStopUseCase,
    required Function() onLogout,
    required Function() onRouteRefreshed,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.getJTPackages();

    await result.fold(
      (failure) async {
        if (failure.message.contains('Sesión expirada') ||
            failure.message.contains('135010037')) {
          onLogout();
        }
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (packages) async {
        _packages = packages;
        
        // Save to selected route logic
        await _savePackagesToSelectedRoute(
          packages,
          selectedRoute,
          addStopUseCase,
          onRouteRefreshed,
        );

        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<int> _savePackagesToSelectedRoute(
    List<JTPackage> packages,
    RouteEntity? selectedRoute,
    AddStopToRoute addStopUseCase,
    Function() onRouteRefreshed,
  ) async {
    if (selectedRoute == null) {
      if (kDebugMode) {
        print('[PackagesProvider] ⚠️ No route selected. Packages imported but not saved.');
      }
      return 0;
    }

    if (kDebugMode) {
       print('[PackagesProvider] 💾 Saving ${packages.length} packages to ${selectedRoute.name}...');
    }

    int savedCount = 0;
    int errorCount = 0;

    for (final package in packages) {
      final stop = StopEntity(
        id: package.waybillNo,
        routeId: selectedRoute.id,
        package: package,
        stopOrder: _calculateNextStopOrder(selectedRoute.stops) + savedCount,
      );

      final result = await addStopUseCase(
        AddStopParams(routeId: selectedRoute.id, stop: stop),
      );

      result.fold(
        (failure) => errorCount++,
        (_) => savedCount++,
      );
    }

    if (kDebugMode) {
      print('[PackagesProvider] ✅ Saved $savedCount packages, $errorCount errors');
    }

    onRouteRefreshed();
    return savedCount;
  }

  /// Calcula el siguiente stopOrder basado en el máximo valor actual.
  /// Esto previene problemas con valores desordenados.
  int _calculateNextStopOrder(List<StopEntity> stops) {
    if (stops.isEmpty) return 1;
    return stops.map((s) => s.stopOrder).reduce(max) + 1;
  }
}
