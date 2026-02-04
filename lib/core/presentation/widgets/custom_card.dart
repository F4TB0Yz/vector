import 'package:flutter/material.dart';
import 'package:vector/core/theme/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool isDarkBackground;
  final Color? borderColor;
  final Color? leftStripColor;
  final bool showBorder;
  final VoidCallback? onTap;
  final double borderRadius;

  const CustomCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.isDarkBackground = false,
    this.borderColor,
    this.showBorder = true,
    this.leftStripColor,
    this.onTap,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? (isDarkBackground ? AppColors.surfaceDark : AppColors.surface);
    final finalBorderColor = borderColor ?? (showBorder ? AppColors.border : Colors.transparent);
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Material(
        color: bgColor,
        // ELIMINADO: borderRadius: radius, <--- Esto causaba el error
        clipBehavior: Clip.antiAlias, 
        shape: RoundedRectangleBorder(
          borderRadius: radius, // El radio se define AQUÍ adentro
          side: BorderSide(
            color: finalBorderColor, 
            width: showBorder ? 1 : 0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
              if (leftStripColor != null)
                Positioned(
                  left: 0, top: 0, bottom: 0, width: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: leftStripColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
