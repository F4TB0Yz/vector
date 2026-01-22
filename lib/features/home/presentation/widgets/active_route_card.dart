import 'package:flutter/material.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    // Si no hay routeId, usamos la fecha como fallback (requerimiento previo)
    final displayId =
        routeId ??
        DateFormat('MMMM d', 'es').format(DateTime.now()).toUpperCase();

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
              CustomCard(
                showBorder: true,
                isDarkBackground: true,
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  LucideIcons.truck,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _RouteProgress(
            deliveredCount: deliveredCount,
            totalCount: totalCount,
          ),
          const SizedBox(height: 24),
          const _NextStopInfo(),
        ],
      ),
    );
  }
}

class _RouteProgress extends StatelessWidget {
  final int deliveredCount;
  final int totalCount;

  const _RouteProgress({
    required this.deliveredCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (totalCount > 0)
        ? (deliveredCount / totalCount).clamp(0.0, 1.0)
        : 0.0;
    final int percentage = (progress * 100).round();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$deliveredCount",
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: "/$totalCount Entregados",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "$percentage% Completado",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.surfaceDark,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _NextStopInfo extends StatelessWidget {
  const _NextStopInfo();

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      backgroundColor: AppColors.background,
      borderRadius: 4,
      showBorder: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(LucideIcons.mapPin, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SIGUIENTE PARADA • 2:30 PM",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Calle 14A 2E 37",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Bonet",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CustomCard(
            showBorder: true,
            isDarkBackground: true,
            padding: const EdgeInsets.all(8),
            borderRadius: 8,
            child: const Icon(
              LucideIcons.navigation,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
