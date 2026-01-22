import 'package:flutter/material.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';
import 'package:vector/core/theme/app_colors.dart';

class RouteCard extends StatelessWidget {
  final String routeId;
  final String status;
  final String estTime;
  final int stops;
  final double distance;
  final VoidCallback? onTap;

  const RouteCard({
    super.key,
    required this.routeId,
    required this.status,
    required this.estTime,
    required this.stops,
    required this.distance,
    this.onTap,
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
      onTap: onTap,
      padding: EdgeInsets.zero,
      backgroundColor: const Color(0xFF1E1E1E),
      showBorder: true,
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID RUTA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      routeId,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getDisplayStatus(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),

          // Stats Section
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.access_time_rounded,
                    label: 'TIEMPO EST.',
                    value: estTime,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.location_on_rounded,
                    label: 'PARADAS',
                    value: stops.toString(),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.straighten_rounded,
                    label: 'DISTANCIA',
                    value: '$distance km',
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {
                // TODO: Navigate to Map
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0x1A00E676),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0x8000E676)),
                  ),
                ),
                child: const Center(
                  child: Text(
                    "VER MAPA",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
