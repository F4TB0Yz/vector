import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:vector/core/database/database_service.dart';
import '../../data/datasources/routes_local_datasource.dart';
import '../../data/repositories/routes_repository_impl.dart';
import '../../domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import '../../domain/usecases/create_route.dart';
import '../../domain/usecases/get_routes.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import '../../domain/repositories/routes_repository.dart'; // Added based on the snippet's routesRepositoryProvider type

// --- Dependencies ---

final routesLocalDataSourceProvider = Provider<RoutesLocalDataSource>((ref) {
  return RoutesLocalDataSourceImpl(DatabaseService.instance);
});

final routesRepositoryProvider = Provider<RoutesRepository>((ref) {
  return RoutesRepositoryImpl(ref.watch(routesLocalDataSourceProvider));
});

final getRoutesUseCaseProvider = Provider<GetRoutes>((ref) {
  return GetRoutes(ref.watch(routesRepositoryProvider));
});

final createRouteUseCaseProvider = Provider<CreateRoute>((ref) {
  return CreateRoute(ref.watch(routesRepositoryProvider));
});

final addStopToRouteUseCaseProvider = Provider<AddStopToRoute>((ref) {
  final repository = ref.watch(routesRepositoryProvider);
  return AddStopToRoute(repository);
});

// --- State ---

class RoutesNotifier extends AsyncNotifier<List<RouteEntity>> {
  @override
  Future<List<RouteEntity>> build() async {
    return _getRoutes();
  }

  Future<List<RouteEntity>> _getRoutes() async {
    final getRoutesUseCase = ref.read(getRoutesUseCaseProvider);
    final result = await getRoutesUseCase();
    return result.fold(
      (failure) =>
          [], // Return empty list on failure for simplicity or handle error state
      (routes) => routes,
    );
  }

  Future<void> createRoute(String name, DateTime date) async {
    state = const AsyncValue.loading();
    final createRouteUseCase = ref.read(createRouteUseCaseProvider);
    final result = await createRouteUseCase(name, date);

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (route) async {
        // Refresh list
        state = await AsyncValue.guard(() => _getRoutes());
      },
    );
  }

  Future<void> addStop(String routeId, StopEntity stop) async {
    final useCase = ref.read(addStopToRouteUseCaseProvider);
    await useCase(AddStopParams(routeId: routeId, stop: stop));
    // No need to refresh routes list as stops are not visible there yet
  }
}

final routesProvider = AsyncNotifierProvider<RoutesNotifier, List<RouteEntity>>(
  RoutesNotifier.new,
);

// Provider to hold the currently selected route for viewing its packages/stops
final selectedRouteProvider = StateProvider<RouteEntity?>((ref) => null);

// --- Filtering and Grouping ---

final routeFilterProvider = StateProvider<int>((ref) => 0); // 0: TODAS, 1: ACTIVA, 2: EN ESPERA

final filteredRoutesProvider = Provider<AsyncValue<List<RouteEntity>>>((ref) {
  final routesAsync = ref.watch(routesProvider);
  final filterIndex = ref.watch(routeFilterProvider);

  return routesAsync.whenData((routes) {
    var filtered = routes;
    
    if (filterIndex == 1) { // ACTIVA (Iniciada pero no terminada)
      filtered = routes.where((r) => r.progress > 0 && r.progress < 1).toList();
    } else if (filterIndex == 2) { // EN ESPERA (No iniciada)
      filtered = routes.where((r) => r.progress == 0).toList();
    }
    
    // Sort by date descending
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  });
});

final groupedRoutesProvider = Provider<AsyncValue<Map<DateTime, List<RouteEntity>>>>((ref) {
  final routesAsync = ref.watch(filteredRoutesProvider);

  return routesAsync.whenData((routes) {
    final Map<DateTime, List<RouteEntity>> groups = {};
    
    for (final route in routes) {
      // Normalize date to midnight
      final dateOnly = DateTime(route.date.year, route.date.month, route.date.day);
      if (!groups.containsKey(dateOnly)) {
        groups[dateOnly] = [];
      }
      groups[dateOnly]!.add(route);
    }
    
    return groups;
  });
});
