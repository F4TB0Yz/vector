import 'package:flutter/material.dart';
import 'package:vector/core/theme/app_colors.dart';

class CustomCard extends StatefulWidget {
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
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  late final Color bgColor;
  late final Color finalBorderColor;
  late final BorderRadius radius;
  late final EdgeInsetsGeometry effectivePadding;
  late final Widget contentChild;

  @override
  void initState() {
    super.initState();
    bgColor = widget.backgroundColor ?? (widget.isDarkBackground ? AppColors.surfaceDark : AppColors.surface);
    finalBorderColor = widget.borderColor ?? (widget.showBorder ? AppColors.border : Colors.transparent);
    radius = BorderRadius.circular(widget.borderRadius);

    // Usar padding por defecto si no se provee
    const defaultPadding = EdgeInsets.all(16);
    effectivePadding = widget.padding ?? defaultPadding;

    // Construir child con padding
    final paddedChild = Padding(
      padding: effectivePadding,
      child: widget.child,
    );

    // Solo usar Stack si hay leftStrip, de lo contrario usar child directo
    contentChild = widget.leftStripColor != null
        ? Stack(
            children: [
              paddedChild,
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: widget.leftStripColor),
                ),
              ),
            ],
          )
        : paddedChild;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: Material(
        color: bgColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: finalBorderColor,
            width: widget.showBorder ? 1 : 0,
          ),
        ),
        child: widget.onTap != null
            ? InkWell(
                onTap: widget.onTap,
                child: contentChild,
              )
            : contentChild,
      ),
    );
  }
}
