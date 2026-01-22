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
    // Determine background color
    final bgColor =
        backgroundColor ??
        (isDarkBackground ? AppColors.surfaceDark : AppColors.surface);

    // Determine final border color
    final finalBorderColor =
        borderColor ?? (showBorder ? AppColors.border : null);

    final border = finalBorderColor != null
        ? Border.all(color: finalBorderColor, width: 1)
        : null;

    final radius = BorderRadius.circular(borderRadius);

    Widget content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
              if (leftStripColor != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(color: leftStripColor),
                ),
            ],
          ),
        ),
      ),
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: border,
      ),
      child: content,
    );
  }
}
