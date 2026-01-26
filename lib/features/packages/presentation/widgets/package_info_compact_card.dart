import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/packages/domain/entities/package_entity.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';

/// Widget compacto que muestra información del paquete
class PackageInfoCompactCard extends StatelessWidget {
  final PackageEntity package;

  const PackageInfoCompactCard({
    super.key,
    required this.package,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF1E1E24),
      showBorder: true,
      borderColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tracking Number
          Row(
            children: [
              const Icon(
                LucideIcons.package,
                size: 16,
                color: Color(0xFF2979FF),
              ),
              const SizedBox(width: 8),
              Text(
                package.id,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Receptor
          Row(
            children: [
              const Icon(
                LucideIcons.user,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  package.receiverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dirección
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 16,
                  color: Color(0xFF00E676),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  package.address,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Teléfono
          Row(
            children: [
              const Icon(
                LucideIcons.phone,
                size: 16,
                color: Color(0xFF2979FF),
              ),
              const SizedBox(width: 8),
              Text(
                package.phone,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // Coordenadas actuales (si existen)
          if (package.coordinates != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2979FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFF2979FF).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: Color(0xFF2979FF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Actual: ${package.coordinates!.lat.toStringAsFixed(6)}, ${package.coordinates!.lng.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: const Color(0xFF2979FF).withValues(alpha: 0.9),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
