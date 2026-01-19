import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';

class FloatingScanButton extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingScanButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Optimization: RepaintBoundary isolates the blur effect
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12), // User requested "not very rounded"
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withAlpha(128), // Transparent dark
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withAlpha(51), // Subtle border
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: const Center(
                  child: Icon(
                    LucideIcons.scanLine,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
