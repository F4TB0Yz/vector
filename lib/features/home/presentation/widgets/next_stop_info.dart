import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

class NextStopInfo extends StatelessWidget {
  const NextStopInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedRoute = context.select<RoutesProvider, RouteEntity?>(
      (p) => p.selectedRoute,
    );
    final stops = selectedRoute?.stops ?? [];
    final nextStop = _findNextStop(stops);

    return CustomCard(
      backgroundColor: AppColors.background,
      borderRadius: 4,
      showBorder: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            nextStop != null ? LucideIcons.mapPin : LucideIcons.checkCircle,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextStop != null ? "SIGUIENTE PARADA" : "LISTO",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextStop?.address ?? "Ruta completada",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (nextStop != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    nextStop.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (nextStop != null)
            const CustomCard(
              showBorder: true,
              isDarkBackground: true,
              padding: EdgeInsets.all(8),
              borderRadius: 8,
              child: Icon(
                LucideIcons.navigation,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  StopEntity? _findNextStop(List<StopEntity> stops) {
    try {
      return stops.firstWhere((stop) => stop.status == PackageStatus.pending);
    } catch (e) {
      return null;
    }
  }
}
