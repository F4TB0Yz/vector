import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';

class FloatingScanButton extends StatelessWidget {
  final VoidCallback onTap;

  const FloatingScanButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Optimization: Removed BackdropFilter (very expensive)
    // Using simple semi-transparent color instead
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xC8252525), // Semi-transparent
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: Border.fromBorderSide(
          BorderSide(
            color: Color(0x33FFFFFF), // Subtle border
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: const Center(
            child: Icon(
              LucideIcons.scanLine,
              color: AppColors.accent,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
