import 'package:flutter/material.dart';
import 'package:vector/core/theme/app_colors.dart';

class RouteProgress extends StatelessWidget {
  final int deliveredCount;
  final int totalCount;

  const RouteProgress({
    super.key,
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
