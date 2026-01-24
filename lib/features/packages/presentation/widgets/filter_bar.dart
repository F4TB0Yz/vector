import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  final List<String> _filters = const ["TODAS", "PENDIENTE", "ENTREGADO", "FALLIDO"];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = context.watch<RoutesProvider>().stopFilterIndex;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                context.read<RoutesProvider>().setStopFilter(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFF2C2C35),
                  borderRadius: BorderRadius.circular(6), // 6px radius for sharp/tech look
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
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
