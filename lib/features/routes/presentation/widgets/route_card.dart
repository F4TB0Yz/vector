import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/routes/presentation/widgets/metric_item.dart';
import 'package:vector/features/routes/presentation/widgets/status_badge.dart';

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
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: activeState
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Neon Strip
                  Container(
                    width: 4,
                    color: statusColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    StatusBadge(
                                      label: _getDisplayStatus(),
                                      color: statusColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.routeId,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildActionIndicator(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MetricItem(
                                icon: LucideIcons.clock,
                                value: widget.estTime,
                                label: 'ETA',
                              ),
                              MetricItem(
                                icon: LucideIcons.mapPin,
                                value: widget.stops.toString(),
                                label: 'PARADAS',
                              ),
                              MetricItem(
                                icon: LucideIcons.navigation,
                                value: '${widget.distance.toStringAsFixed(1)} KM',
                                label: 'DIST.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                            AppColors.primary.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                          stops: [
                            _sweepController.value - 0.2,
                            _sweepController.value,
                            _sweepController.value + 0.2,
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
    );
  }

  Widget _buildActionIndicator() {
    final bool isHighlighted = widget.isSelected || _isActivating;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isHighlighted ? Colors.transparent : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isActivating)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                widget.isSelected ? LucideIcons.check : LucideIcons.play,
                size: 14,
                color: isHighlighted ? Colors.white : AppColors.primary,
              ),
            const SizedBox(width: 8),
            Text(
              _isActivating ? '...' : widget.isSelected ? 'ACTIVA' : 'INICIAR',
              style: TextStyle(
                color: isHighlighted ? Colors.white : AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
