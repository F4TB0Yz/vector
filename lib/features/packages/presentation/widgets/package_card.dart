import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector/core/presentation/widgets/custom_card.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vibration/vibration.dart';

class PackageCard extends StatelessWidget {
  final StopEntity stop;
  final VoidCallback? onTap;
  final VoidCallback? onDelivered;
  final VoidCallback? onFailed;
  final VoidCallback? onAssignLocation;

  const PackageCard({
    super.key,
    required this.stop,
    this.onTap,
    this.onDelivered,
    this.onFailed,
    this.onAssignLocation,
  });

  Color _getStatusColor() {
    final package = stop.package;
    switch (package.status) {
      case PackageStatus.pending:
        return const Color(0xFFFFD740); // Amarillo neon
      case PackageStatus.delivered:
        return const Color(0xFF00E676); // Verde neon
      case PackageStatus.failed:
        return const Color(0xFFFF5252); // Rojo neon
      case PackageStatus.inTransit:
      case PackageStatus.outForDelivery:
        return AppColors.primary; // Azul neon
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _makeCall() async {
    final package = stop.package;
    final Uri launchUri = Uri(scheme: 'tel', path: package.phone);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendWhatsApp() async {
    final package = stop.package;
    // Remove non-numeric characters for WhatsApp link
    final cleanPhone = package.phone.replaceAll(RegExp(r'\D'), '');
    final Uri launchUri = Uri.parse("https://wa.me/$cleanPhone");
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  void _performVibration() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 50); // Short vibration
    }
  }

  @override
  Widget build(BuildContext context) {
    final package = stop.package;
    final statusColor = _getStatusColor();

    // Verificar si es un paquete agrupado
    final isGroupedPackage =
        package is JTPackage && package.isGrouped;

    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      backgroundColor: isGroupedPackage
          ? const Color(0xFF1A1F2E)
          : const Color(0xFF1E1E24),
      showBorder: true,
      borderColor: isGroupedPackage
          ? AppColors.primary.withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.05),
      child: Stack(
        children: [
          // Franja lateral de estado
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              color: statusColor,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Stop Order y Estado
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.3)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${stop.stopOrder}',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.id,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (isGroupedPackage)
                              Text(
                                'PAQUETE AGRUPADO',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        package.status.toLocalizedString().toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),

              // Body: Dirección (Título) y Receptor (Subtítulo)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.address,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(LucideIcons.user,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        Text(
                          package.receiverName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Acciones de contacto
                    Row(
                      children: [
                        _ContactAction(
                          icon: LucideIcons.phone,
                          label: package.phone,
                          onTap: _makeCall,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        _ContactAction(
                          icon: LucideIcons.messageSquare,
                          label: 'WhatsApp',
                          onTap: _sendWhatsApp,
                          color: const Color(0xFF25D366),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (package.status == PackageStatus.pending) ...[
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'ENTREGADO',
                          color: AppColors.accent,
                          onPressed: () {
                            _performVibration();
                            onDelivered?.call();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          label: 'FALLIDO',
                          color: const Color(0xFFFF5252),
                          onPressed: () {
                            _performVibration();
                            onFailed?.call();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botón para asignar/editar coordenadas (siempre visible si hay callback)
              if (onAssignLocation != null) ...[
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildActionButton(
                    label: package.coordinates == null 
                        ? 'ASIGNAR UBICACIÓN' 
                        : 'EDITAR UBICACIÓN',
                    icon: LucideIcons.mapPin,
                    color: AppColors.primary,
                    onPressed: () {
                      _performVibration();
                      onAssignLocation!();
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
