import 'package:flutter/material.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

class PackageCardCompressed extends StatelessWidget {
  final StopEntity stop;

  const PackageCardCompressed({super.key, required this.stop});

  @override
  Widget build(BuildContext context) {
    final package = stop.package;
    final Color statusColor = _getStatusColor(package.status);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(
          children: [
            // Status Indicator Bar (Neon)
            Container(
              width: 4,
              height: double.infinity,
              color: statusColor,
            ),
            const SizedBox(width: 12),
            // Route Stop Number
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              alignment: Alignment.center,
              child: Text(
                '${stop.stopOrder}',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Address and Name
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.address,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    package.receiverName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Status Indicator (Small Circle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(PackageStatus status) {
    switch (status) {
      case PackageStatus.delivered:
        return AppColors.accent;
      case PackageStatus.failed:
        return const Color(0xFFFF5252);
      case PackageStatus.pending:
      default:
        return AppColors.primary;
    }
  }
}
