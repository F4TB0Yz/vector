import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/packages/presentation/providers/jt_package_providers.dart';

// Provides the currently selected filter index (0 for "TODAS", 1 for "PENDIENTE", etc.)
final packageFilterIndexProvider = StateProvider<int>((ref) => 0);

// Provides the filtered list of StopEntity based on the selected filter and route stops
final filteredStopsProvider = Provider<List<StopEntity>>((ref) {
  final stops = ref.watch(routeStopsProvider);
  final selectedFilterIndex = ref.watch(packageFilterIndexProvider);

  final List<String> filters = ["TODAS", "PENDIENTE", "ENTREGADO", "FALLIDO"];
  final currentFilter = filters[selectedFilterIndex];

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
});
