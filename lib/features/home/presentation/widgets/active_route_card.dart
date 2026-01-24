import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/home/presentation/widgets/next_stop_info.dart';
import 'package:vector/features/home/presentation/widgets/route_progress.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

class ActiveRouteCard extends StatelessWidget {
  final String? routeId;
  final int deliveredCount;
  final int totalCount;

  const ActiveRouteCard({
    super.key,
    this.routeId,
    this.deliveredCount = 0,
    this.totalCount = 1, // Avoid division by zero default
  });

  @override
  Widget build(BuildContext context) {
    final selectedRoute = context.watch<RoutesProvider>().selectedRoute;
    
    // Si no hay routeId, usamos la fecha como fallback (requerimiento previo)
    final displayId =
        routeId ??
        (selectedRoute?.name ?? DateFormat('MMMM d', 'es').format(DateTime.now()).toUpperCase());

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
                            fontWeight: FontWeight.w900,
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

