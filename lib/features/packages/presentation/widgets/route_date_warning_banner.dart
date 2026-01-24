import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

class RouteDateWarningBanner extends StatelessWidget {
  const RouteDateWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedRoute = context.watch<RoutesProvider>().selectedRoute;
    final isRouteForToday = selectedRoute != null && DateUtils.isSameDay(selectedRoute.date, DateTime.now());

    if (selectedRoute == null || isRouteForToday) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(LucideIcons.info, color: Color(0xFF00E5FF), size: 16),
          const SizedBox(width: 8),
          Text(
            'Ruta de fecha: ${DateFormat('yyyy-MM-dd').format(selectedRoute.date)}',
            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
