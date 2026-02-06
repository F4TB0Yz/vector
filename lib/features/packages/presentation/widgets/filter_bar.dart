import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  final List<String> _filters = const [
    "TODAS",
    "PENDIENTE",
    "ENTREGADO",
    "FALLIDO",
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.select<RoutesProvider, int>(
      (p) => p.stopFilterIndex,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                context.read<RoutesProvider>().setStopFilter(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
