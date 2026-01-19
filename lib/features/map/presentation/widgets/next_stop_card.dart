import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NextStopCard extends StatelessWidget {
  final String stopNumber;
  final String timeAway;
  final String address;
  final String packageType;
  final String weight;
  final bool isPriority;
  final String? note;
  final VoidCallback? onScan;
  final VoidCallback? onClose;

  const NextStopCard({
    super.key,
    required this.stopNumber,
    required this.timeAway,
    required this.address,
    required this.packageType,
    required this.weight,
    this.isPriority = false,
    this.note,
    this.onScan,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Color principal de la tarjeta (Cyan/Azul vibrante de la imagen)
    const accentColor = Color(0xFF00B0FF);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Fondo oscuro
        borderRadius: BorderRadius.circular(4), // Bordes rectos/industriales
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Se ajusta al contenido
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superior de progreso/indicador (opcional, para dar el toque "Next Stop")
          Container(
            height: 4,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
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
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stopNumber.toUpperCase(), // Ej: STOP 04
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          timeAway.toUpperCase(), // Ej: 3 MIN AWAY
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
                  address,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // Detalles del Paquete
                Row(
                  children: [
                    _DetailItem(
                      icon: LucideIcons.package,
                      text: packageType,
                    ),
                    const SizedBox(width: 16),
                    _DetailItem(
                      icon: LucideIcons.scale, // Alternativa para peso
                      text: weight,
                    ),
                    if (isPriority) ...[
                      const Spacer(),
                      const Icon(
                        LucideIcons.star,
                        color: Color(0xFFFFD740), // Amarillo
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'PRIORIDAD',
                        style: TextStyle(
                          color: Color(0xFFFFD740),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Nota (si existe)
                if (note != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
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
                            note!,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.scanLine, size: 20),
                        const SizedBox(width: 8),
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
              ],
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
        Icon(
          icon,
          color: Colors.grey[500],
          size: 16,
        ),
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
