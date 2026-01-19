import 'package:flutter/material.dart';

class HomeActionButtons extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onNewRouteTap;

  const HomeActionButtons({
    super.key,
    required this.onScanTap,
    required this.onNewRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    const neonBlue = Color(0xFF00B0FF); // Cyan-like blue from image

    return Row(
      children: [
        // Scan Button (Outlined)
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: onScanTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: neonBlue,
                side: const BorderSide(color: neonBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'ESCANEAR',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: neonBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // New Route Button (Filled)
        Expanded(
          child: SizedBox(
            height: 54,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x6600B0FF), // Blue glow
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onNewRouteTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_road_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'NUEVA RUTA',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
