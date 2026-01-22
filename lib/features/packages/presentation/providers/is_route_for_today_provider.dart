import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

final isRouteForTodayProvider = Provider<bool>((ref) {
  final selectedRoute = ref.watch(selectedRouteProvider);

  if (selectedRoute == null) {
    return false;
  }

  final today = DateTime.now();
  return DateUtils.isSameDay(selectedRoute.date, today);
});
