import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';

class RouteCard extends StatefulWidget {
  final String routeId;
  final String status;
  final String estTime;
  final int stops;
  final double distance;
  final bool isSelected;
  final VoidCallback? onSelect;

  const RouteCard({
    super.key,
    required this.routeId,
    required this.status,
    required this.estTime,
    required this.stops,
    required this.distance,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> with SingleTickerProviderStateMixin {
  bool _isActivating = false;
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.isSelected || _isActivating) return;

    setState(() => _isActivating = true);
    HapticFeedback.heavyImpact();
    _sweepController.forward(from: 0.0);

    // Animación notable antes de navegar
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      widget.onSelect?.call();
      if (mounted) setState(() => _isActivating = false);
    }
  }

  Color _getStatusColor() {
    switch (widget.status.toUpperCase()) {
      case 'READY':
        return const Color(0xFF00E676); // Neon Green
      case 'ACTIVE':
        return const Color(0xFF2979FF); // Electric Blue
      case 'COMPLETED':
        return Colors.blueGrey;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getDisplayStatus() {
    switch (widget.status.toUpperCase()) {
      case 'READY':
        return 'LISTA';
      case 'ACTIVE':
        return 'ACTIVA';
      case 'COMPLETED':
        return 'COMPLETADA';
      default:
        return widget.status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final bool activeState = widget.isSelected || _isActivating;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: activeState
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: -5,
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  color: activeState
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : const Color(0xFF1E1E24).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: activeState
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status Neon Strip
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: statusColor,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ID RUTA',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.routeId,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _StatusBadge(
                                    label: _getDisplayStatus(),
                                    color: statusColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _MetricItem(
                                    icon: LucideIcons.clock,
                                    value: widget.estTime,
                                    label: 'ETA',
                                  ),
                                  _MetricItem(
                                    icon: LucideIcons.mapPin,
                                    value: widget.stops.toString(),
                                    label: 'PARADAS',
                                  ),
                                  _MetricItem(
                                    icon: LucideIcons.navigation,
                                    value: '${widget.distance.toStringAsFixed(1)} KM',
                                    label: 'DIST.',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _SelectButton(
                                isSelected: widget.isSelected,
                                isActivating: _isActivating,
                                onTap: _handleTap,
                                accentColor: widget.isSelected ? Colors.white : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Selection Sweep Animation (Neon Light bar passing through)
              if (_isActivating)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _sweepController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withValues(alpha: 0.05),
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.primary.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                            stops: [
                              _sweepController.value - 0.3,
                              _sweepController.value - 0.15,
                              _sweepController.value,
                              _sweepController.value + 0.15,
                              _sweepController.value + 0.3,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SelectButton extends StatelessWidget {
  final bool isSelected;
  final bool isActivating;
  final VoidCallback? onTap;
  final Color accentColor;

  const _SelectButton({
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
