import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart'; // Import for AppColors
import 'package:vector/features/map/domain/entities/stop_entity.dart'; // Import for StopEntity
import 'package:vibration/vibration.dart'; // Import for vibration feedback

class NextStopCard extends StatelessWidget {
  final StopEntity stop;
  final VoidCallback? onScan;
  final VoidCallback? onClose;
  final void Function(StopEntity stop)? onDelivered;
  final void Function(StopEntity stop)? onFailed;

  const NextStopCard({
    super.key,
    required this.stop,
    this.onScan,
    this.onClose,
    this.onDelivered,
    this.onFailed,
  });

  void _performVibration() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 50); // Short vibration
    }
  }

  @override
  Widget build(BuildContext context) {
    // Helper variables for easier access
    final String stopNumberText = "PARADA ${stop.stopOrder}";
    const String timeAwayText = "A 3 MIN"; // Placeholder, actual logic needed
    final String addressText = stop.address;
    const String packageTypeText = "Paquete"; // Placeholder (PackageEntity doesn't have packageType)
    const String weightText = "N/A"; // Placeholder (PackageEntity doesn't have weight)
    final String? noteText = stop.package.notes;

    // Color principal de la tarjeta (Cyan/Azul vibrante de la imagen)
    const accentColor = Color(0xFF00B0FF);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Fondo oscuro
        borderRadius: BorderRadius.all(
          Radius.circular(4),
        ), // Bordes rectos/industriales
        border: Border.fromBorderSide(
          BorderSide(color: Color(0x1AFFFFFF), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column( // Main Column of NextStopCard
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superior de progreso/indicador (opcional, para dar el toque "Next Stop")
          Container(
            height: 4,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF00B0FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Badge Stop y Tiempo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFF00B0FF),
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                              child: Text(
                                stopNumberText.toUpperCase(), // Ej: STOP 04
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              timeAwayText.toUpperCase(), // Ej: 3 MIN AWAY
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: onClose,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          icon: const Icon(
                            LucideIcons.x,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                
                    const SizedBox(height: 12),
                  
                    // Dirección Principal
                    Text(
                      addressText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  
                    const SizedBox(height: 16),
                  
                    // Detalles del Paquete
                    const Row(
                      children: [
                        _DetailItem(icon: LucideIcons.package, text: packageTypeText),
                        SizedBox(width: 16),
                        _DetailItem(icon: LucideIcons.scale, text: weightText),
                      ],
                    ),
                  
                    const SizedBox(height: 16),
                  
                    // Nota (si existe)
                    if (noteText != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LucideIcons.info,
                              color: Colors.grey[500],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                noteText,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  
                    const SizedBox(height: 16),
                  
                    // Botón Escanear
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.scanLine, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ESCANEAR PAQUETE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Entregado / Fallido buttons
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _performVibration();
                              onDelivered?.call(stop);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.accent,
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: AppColors.accent.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(color: AppColors.accent, width: 1),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Entregado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _performVibration();
                              onFailed?.call(stop);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: const Color(0xFFEF5350),
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: const Color(0xFFEF5350).withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(color: Color(0xFFEF5350), width: 1),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Fallido',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}