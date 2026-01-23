import 'package:flutter/material.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';
import 'package:vector/core/theme/app_colors.dart';

class RouteCard extends StatelessWidget {
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

  Color _getStatusColor() {
    switch (status.toUpperCase()) {
      case 'READY':
        return const Color(0xFF00E676);
      case 'ACTIVE':
        return AppColors.primary;
      case 'COMPLETED':
        return Colors.blueGrey;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getDisplayStatus() {
    switch (status.toUpperCase()) {
      case 'READY':
        return 'LISTA';
      case 'ACTIVE':
        return 'ACTIVA';
      case 'COMPLETED':
        return 'COMPLETADA';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return CustomCard(
      padding: EdgeInsets.zero,
      backgroundColor: const Color(0xFF1E1E1E),
      showBorder: true,
      borderColor: isSelected 
          ? AppColors.primary.withValues(alpha: 0.5) 
          : Colors.white.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Content Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ID:',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            routeId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Compact Stats Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CompactStat(
                              icon: Icons.access_time_rounded,
                              value: estTime,
                            ),
                            _StatDivider(),
                            _CompactStat(
                              icon: Icons.location_on_rounded,
                              value: '$stops stops',
                            ),
                            _StatDivider(),
                            _CompactStat(
                              icon: Icons.straighten_rounded,
                              value: '$distance km',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge (Mini)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getDisplayStatus(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),

          // Action Button (Compact)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: InkWell(
              onTap: onSelect,
              borderRadius: BorderRadius.circular(4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primary.withValues(alpha: 0.2) 
                      : const Color(0x1A00E676),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0x8000E676),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    isSelected ? "SELECCIONADA" : "Seleccionar",
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _CompactStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey[500], size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
    );
  }
}
