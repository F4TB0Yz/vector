import 'package:flutter/foundation.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart' as map;
import '../../data/datasources/routes_preferences_datasource.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/usecases/create_route.dart';
import '../../domain/usecases/get_routes.dart';

class RoutesProvider extends ChangeNotifier {
  final GetRoutes _getRoutesUseCase;
  final CreateRoute _createRouteUseCase;
  final RoutesPreferencesDataSource _prefsDataSource;

  // State
  List<RouteEntity> _routes = [];
  RouteEntity? _selectedRoute;
  int _filterIndex = 0; // 0: TODAS, 1: ACTIVA, 2: EN ESPERA
  int _stopFilterIndex = 0; // 0: TODAS, 1: PENDIENTE, 2: ENTREGADO, 3: FALLIDO
  bool _isLoading = false;
  String? _error;

  // Getters
  List<RouteEntity> get routes => _routes;
  RouteEntity? get selectedRoute => _selectedRoute;
  int get filterIndex => _filterIndex;
  int get stopFilterIndex => _stopFilterIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Derived State
  List<RouteEntity> get filteredRoutes {
    if (_filterIndex == 1) {
      // ACTIVA (Iniciada pero no terminada)
      return _routes.where((r) => r.progress > 0 && r.progress < 1).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } else if (_filterIndex == 2) {
      // EN ESPERA (No iniciada)
      return _routes.where((r) => r.progress == 0).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    // TODAS
    return List.from(_routes)..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<DateTime, List<RouteEntity>> get groupedRoutes {
    final Map<DateTime, List<RouteEntity>> groups = {};
    for (final route in filteredRoutes) {
      final dateOnly =
          DateTime(route.date.year, route.date.month, route.date.day);
      if (!groups.containsKey(dateOnly)) {
        groups[dateOnly] = [];
      }
      groups[dateOnly]!.add(route);
    }
    return groups;
  }

  List<StopEntity> get filteredStops {
    final route = _selectedRoute;
    if (route == null) return [];

    final stops = List<StopEntity>.from(route.stops)
      ..sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    final List<String> filters = ["TODAS", "PENDIENTE", "ENTREGADO", "FALLIDO"];
    final currentFilter = filters[_stopFilterIndex];

    return stops.where((stop) {
      switch (currentFilter) {
        case 'PENDIENTE':
          return stop.status == PackageStatus.pending;
        case 'ENTREGADO':
          return stop.status == PackageStatus.delivered;
        case 'FALLIDO':
          return stop.status == PackageStatus.failed;
        case 'TODAS':
        default:
          return true;
      }
    }).toList();
  }

  RoutesProvider({
    required GetRoutes getRoutesUseCase,
    required CreateRoute createRouteUseCase,
    required RoutesPreferencesDataSource prefsDataSource,
  })  : _getRoutesUseCase = getRoutesUseCase,
        _createRouteUseCase = createRouteUseCase,
        _prefsDataSource = prefsDataSource;

  Future<void> loadRoutes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getRoutesUseCase();
    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (routes) {
        _routes = List<RouteEntity>.from(routes);

        // Lógica de Persistencia de Ruta Diaria
        final savedRouteId = _prefsDataSource.getSelectedRouteId();
        final savedDate = _prefsDataSource.getSelectedRouteDate();
        final today = DateTime.now();
        final todayDateOnly = DateTime(today.year, today.month, today.day);

        if (savedRouteId != null && savedDate != null) {
          final savedDateOnly =
              DateTime(savedDate.year, savedDate.month, savedDate.day);

          if (savedDateOnly.isAtSameMomentAs(todayDateOnly)) {
            // Es de hoy, intentar restaurar
            try {
              _selectedRoute =
                  _routes.firstWhere((r) => r.id == savedRouteId);
            } catch (_) {
              // No encontrada, limpiar
              _prefsDataSource.clearSelectedRoute();
              _selectedRoute = null;
            }
          } else {
            // Es antigua, limpiar
            _prefsDataSource.clearSelectedRoute();
            _selectedRoute = null;
          }
        } else if (_selectedRoute != null) {
          // Mantener selección actual si ya existe en memoria (después de una actualización)
          try {
            _selectedRoute =
                _routes.firstWhere((r) => r.id == _selectedRoute!.id);
          } catch (_) {
            _selectedRoute = null;
          }
        }

        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> createRoute(String name, DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _createRouteUseCase(name, date);

    await result.fold(
      (failure) async {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (route) async {
        await loadRoutes(); // Reload to include new route and sort
      },
    );
  }

  void selectRoute(RouteEntity? route) {
    _selectedRoute = route;
    if (route != null) {
      _prefsDataSource.saveSelectedRoute(route.id, DateTime.now());
    } else {
      _prefsDataSource.clearSelectedRoute();
    }
    notifyListeners();
  }

  void setFilter(int index) {
    _filterIndex = index;
    notifyListeners();
  }

  Future<void> addStop(StopEntity stop, AddStopToRoute useCase) async {
    final route = _selectedRoute;
    if (route == null) return;

    // Optimistic Update
    final newStops = List<StopEntity>.from(route.stops)..add(stop);
    final updatedRoute = route.copyWith(stops: newStops);
    selectRoute(updatedRoute);

    final result = await useCase(AddStopParams(routeId: route.id, stop: stop));

    result.fold(
      (failure) {
        // Rollback
        selectRoute(route);
        _error = failure.message;
        notifyListeners();
      },
      (_) {
        // Success - maybe reload strictly or just keep optimistic?
        // Keep optimistic for speed, reload in background if needed.
      },
    );
  }

  void setStopFilter(int index) {
    _stopFilterIndex = index;
    notifyListeners();
  }

  /// Updates a route in the list and selectedRoute if applicable.
  /// Handles both RouteEntity types by matching IDs and updating stops.
  void updateRoute(map.RouteEntity updatedRoute) {
    // Update in the list
    final index = _routes.indexWhere((r) => r.id == updatedRoute.id);
    if (index != -1) {
      _routes[index] = _routes[index].copyWith(
        stops: updatedRoute.stops,
        progress: updatedRoute.progress,
      );
    }

    // Update selected route
    if (_selectedRoute?.id == updatedRoute.id) {
      _selectedRoute = _selectedRoute!.copyWith(
        stops: updatedRoute.stops,
        progress: updatedRoute.progress,
      );
    }
    
    notifyListeners();
  }

  
  /// Helper to refresh state externally (e.g. after adding stops)
  void invalidate() {
    loadRoutes();
  }
}
