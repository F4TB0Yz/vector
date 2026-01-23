import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';

class SelectButton extends StatelessWidget {
  final bool isSelected;
  final bool isActivating;
  final VoidCallback? onTap;
  final Color accentColor;

  const SelectButton({
    super.key,
    required this.isSelected,
    required this.isActivating,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = isSelected || isActivating;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isHighlighted ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isHighlighted ? Colors.transparent : AppColors.primary,
              width: 1.5,
            ),
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActivating) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else if (isSelected) ...[
                  const Icon(LucideIcons.check, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  isActivating
                      ? 'ACTIVANDO...'
                      : isSelected
                          ? 'RUTA SELECCIONADA'
                          : 'INICIAR RUTA',
                  style: TextStyle(
                    color: isHighlighted ? Colors.white : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
