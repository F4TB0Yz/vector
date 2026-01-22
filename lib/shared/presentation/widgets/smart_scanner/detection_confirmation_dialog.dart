import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DetectionConfirmationDialog extends StatelessWidget {
  final BarcodeCapture capture;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DetectionConfirmationDialog({
    super.key,
    required this.capture,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final barcode = capture.barcodes.firstOrNull;
    final codeValue = barcode?.rawValue ?? 'Código desconocido';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E), // Surface color
          borderRadius: BorderRadius.all(Radius.circular(16)),
          border: Border.fromBorderSide(
            BorderSide(color: Color(0x14FFFFFF), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container with Green Glow
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF252525),
                borderRadius: BorderRadius.all(Radius.circular(20)),
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0x4D00E676), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x2600E676),
                    blurRadius: 24,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded, // Relevant icon for text
                color: Color(0xFF00E676),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              '¿Procesar Código?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle / Code Display
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 15,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Se ha detectado el código\n'),
                  TextSpan(
                    text: codeValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Courier', // Monospace for technical feel
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: '. ¿Deseas continuar?'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Primary Action Button (Green)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).copyWith(
                      shadowColor: WidgetStateProperty.all(
                        const Color(0xFF00E676).withValues(alpha: 0.5),
                      ),
                      elevation: WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.pressed) ? 2 : 8;
                      }),
                    ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CONFIRMAR Y PROCESAR',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.check_rounded, size: 20, color: Colors.black),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Secondary Action Button (Outline)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCancel();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF252525),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
