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
  final bool isAnimatedBorder;

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
    this.isAnimatedBorder = false,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 3), vsync: this);
    if (widget.isAnimatedBorder) {
      _controller.repeat();
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(CustomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimatedBorder != oldWidget.isAnimatedBorder) {
      if (widget.isAnimatedBorder) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!widget.isAnimatedBorder) {
      return;
    }
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.repeat();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine background color
    final bgColor = widget.backgroundColor ??
        (widget.isDarkBackground
            ? AppColors.surfaceDark
            : AppColors.surface);

    // Determine final border color
    // If animated, we don't draw the static border
    final finalBorderColor = widget.borderColor ??
        (widget.showBorder ? AppColors.border : null);

    final border = (finalBorderColor != null && !widget.isAnimatedBorder)
        ? Border.all(color: finalBorderColor, width: 1)
        : null;

    final radius = BorderRadius.circular(widget.borderRadius);

    Widget content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: radius,
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Padding(
                padding: widget.padding ?? const EdgeInsets.all(16),
                child: widget.child,
              ),
              if (widget.leftStripColor != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    color: widget.leftStripColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.isAnimatedBorder) {
      return Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: radius,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gradient spinner
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: SweepGradient(
                            center: Alignment.center,
                            colors: const [
                              AppColors.primary,
                              Colors.transparent,
                              AppColors.accent,
                              Colors.transparent,
                              AppColors.primary,
                            ],
                            transform: GradientRotation(_controller.value * 6.28),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Inner content masking the center
            Container(
              margin: const EdgeInsets.all(1.5), // Border width
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: radius,
              ),
              child: content,
            ),
          ],
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: radius,
        border: border,
      ),
      child: content,
    );
  }
}