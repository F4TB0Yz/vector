import 'package:flutter/material.dart';
import 'package:vector/core/theme/app_colors.dart';

class NeonCorners extends StatelessWidget {
  const NeonCorners({super.key});

  @override
  Widget build(BuildContext context) {
    const double length = 40;
    const double thickness = 4;
    const Color color = AppColors.accent;

    return Stack(
      children: [
        // Top Left
        Positioned(
          top: 0,
          left: 0,
          child: Container(width: length, height: thickness, color: color),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: Container(width: thickness, height: length, color: color),
        ),
        // Top Right
        Positioned(
          top: 0,
          right: 0,
          child: Container(width: length, height: thickness, color: color),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(width: thickness, height: length, color: color),
        ),
        // Bottom Left
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(width: length, height: thickness, color: color),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(width: thickness, height: length, color: color),
        ),
        // Bottom Right
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(width: length, height: thickness, color: color),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(width: thickness, height: length, color: color),
        ),
      ],
    );
  }
}
