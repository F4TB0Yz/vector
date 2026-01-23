import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';
import 'package:vector/core/theme/app_colors.dart';

class NextStopInfo extends StatelessWidget {
  const NextStopInfo({super.key});

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
