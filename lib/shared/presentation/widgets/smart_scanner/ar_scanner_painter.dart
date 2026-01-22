import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vector/core/theme/app_colors.dart';

class ARScannerPainter extends CustomPainter {
  final Size imgSize;
  final List<Barcode> barcodes;
  final Size screenSize;

  ARScannerPainter({
    required this.imgSize,
    required this.barcodes,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imgSize.width == 0 || imgSize.height == 0) return;

    final Paint paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth =
          4 // Thicker for better visibility
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final Paint glowPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth =
          8 // Much wider glow
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        6,
      ); // Stronger blur

    // --- COORDINATE MAPPING LOGIC ---

    // 1. Detect Orientation Mismatch
    // Most phone cameras sensors are Landscape (e.g. 1920x1080).
    // The screen is usually Portrait (e.g. 400x800).
    // BoxFit.cover rotates the image 90 degrees visually to fit.

    double sourceWidth = imgSize.width;
    double sourceHeight = imgSize.height;

    bool screenIsPortrait = screenSize.width < screenSize.height;
    bool imageIsLandscape = imgSize.width > imgSize.height;

    // If orientation differs, we act as if the image dimensions are swapped
    // because the "source" effectively becomes the rotated image.
    if (screenIsPortrait && imageIsLandscape) {
      sourceWidth = imgSize.height;
      sourceHeight = imgSize.width;
    }

    // 2. Calculate BoxFit.cover scale
    final double scaleX = screenSize.width / sourceWidth;
    final double scaleY = screenSize.height / sourceHeight;
    final double scale = (scaleX > scaleY)
        ? scaleX
        : scaleY; // max(scaleX, scaleY)

    // 3. Calculate Center Offsets
    // These offsets center the scaled image within the screen.
    // If the image is wider than screen, offsetX is negative (centering it).
    final double offsetX = (screenSize.width - sourceWidth * scale) / 2;
    final double offsetY = (screenSize.height - sourceHeight * scale) / 2;

    for (final barcode in barcodes) {
      if (barcode.corners.isEmpty) continue;

      final Path path = Path();
      final corners = barcode.corners;

      for (int i = 0; i < corners.length; i++) {
        final point = corners[i];

        // 4. Transform Point
        // We apply the same scale and offset to the corner points.

        double x = point.dx;
        double y = point.dy;

        final double destX = x * scale + offsetX;
        final double destY = y * scale + offsetY;

        if (i == 0) {
          path.moveTo(destX, destY);
        } else {
          path.lineTo(destX, destY);
        }
      }
      path.close();

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(ARScannerPainter oldDelegate) {
    return oldDelegate.imgSize != imgSize ||
        oldDelegate.barcodes != barcodes ||
        oldDelegate.screenSize != screenSize;
  }
}
