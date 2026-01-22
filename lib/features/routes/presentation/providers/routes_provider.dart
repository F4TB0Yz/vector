import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector/core/database/database_service.dart';
import '../../data/datasources/routes_local_datasource.dart';
import '../../data/repositories/routes_repository_impl.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/usecases/create_route.dart';
import '../../domain/usecases/get_routes.dart';

// --- Dependencies ---

final routesLocalDataSourceProvider = Provider<RoutesLocalDataSource>((ref) {
  return RoutesLocalDataSourceImpl(DatabaseService.instance);
});

final routesRepositoryProvider = Provider<RoutesRepositoryImpl>((ref) {
  return RoutesRepositoryImpl(ref.watch(routesLocalDataSourceProvider));
});

final getRoutesUseCaseProvider = Provider<GetRoutes>((ref) {
  return GetRoutes(ref.watch(routesRepositoryProvider));
});

final createRouteUseCaseProvider = Provider<CreateRoute>((ref) {
  return CreateRoute(ref.watch(routesRepositoryProvider));
});

// --- State ---

class RoutesNotifier extends AsyncNotifier<List<RouteEntity>> {
  @override
  Future<List<RouteEntity>> build() async {
    return _fetchRoutes();
  }

  Future<List<RouteEntity>> _fetchRoutes() async {
    final getRoutes = ref.read(getRoutesUseCaseProvider);
    final result = await getRoutes();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (routes) => routes,
    );
  }

  Future<void> createRoute(String name, DateTime date) async {
    state = const AsyncValue.loading();
    
    final createRoute = ref.read(createRouteUseCaseProvider);
    final result = await createRoute(name, date);
    
    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (newRoute) async {
        // Refresh the list after creation
        ref.invalidateSelf(); 
        await future; // Wait for the refresh to complete
      },
    );
  }
}

final routesProvider = AsyncNotifierProvider<RoutesNotifier, List<RouteEntity>>(RoutesNotifier.new);
