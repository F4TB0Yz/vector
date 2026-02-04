import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/home/presentation/widgets/next_stop_info.dart';
import 'package:vector/features/home/presentation/widgets/route_progress.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

class ActiveRouteCard extends StatelessWidget {
  const ActiveRouteCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final selectedRoute = context.watch<RoutesProvider>().selectedRoute;

    final totalCount = selectedRoute?.stops.length ?? 0;
    final deliveredCount = selectedRoute?.stops
            .where((stop) => stop.status == PackageStatus.delivered)
            .length ??
        0;
    
    // Si no hay routeId, usamos la fecha como fallback (requerimiento previo)
    final displayId =
        selectedRoute?.name ?? DateFormat('MMMM d', 'es').format(DateTime.now()).toUpperCase();

    return CustomCard(
      width: double.infinity,
      leftStripColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "RUTA ACTIVA",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayId,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                    ),
                  ],
                ),
              ),
              const CustomCard(
                showBorder: true,
                isDarkBackground: true,
                padding: EdgeInsets.all(10),
                child: Icon(
                  LucideIcons.truck,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          RouteProgress(
            deliveredCount: deliveredCount,
            totalCount: totalCount,
          ),
          const SizedBox(height: 24),
          const NextStopInfo(),
        ],
      ),
    );
  }
}

