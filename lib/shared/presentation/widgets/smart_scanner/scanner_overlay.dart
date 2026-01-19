import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/shared/presentation/widgets/smart_scanner/neon_corners.dart';

class ScannerOverlay extends StatelessWidget {
  final MobileScannerController controller;

  const ScannerOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // RECTANGULAR SHAPE FOR BARCODES AND QR (320x160)
    const double scanZoneWidth = 320;
    const double scanZoneHeight = 160;

    return Stack(
      children: [
        // Semi-transparent dimming
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withAlpha(128),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: scanZoneWidth,
                  height: scanZoneHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Neon Corners (Rectangular Shape)
        Align(
          alignment: Alignment.center,
          child: Container(
            width: scanZoneWidth,
            height: scanZoneHeight,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent.withAlpha(77), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const NeonCorners(),
          ),
        ),

        // Controls & Hints
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Hint
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Alinea el código dentro del marco',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // Bottom Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: controller,
                  builder: (context, state, child) {
                    final isFlashOn = state.torchState == TorchState.on;
                    final currentZoom = state.zoomScale;
                    // Simplify: if zoom > 0.1 consider it zoomed.
                    final isZoomed = currentZoom > 0.1;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Flash Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: isFlashOn ? AppColors.accent.withAlpha(51) : Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () async {
                              try {
                                await controller.toggleTorch();
                              } catch (e) {
                                debugPrint('Error toggling torch: $e');
                              }
                            },
                            icon: Icon(
                              isFlashOn ? Icons.flash_on : Icons.flash_off,
                              color: isFlashOn ? AppColors.accent : Colors.white,
                              size: 28,
                            ),
                            tooltip: 'Alternar Flash',
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Zoom Toggle (Cycle 0.0 -> 0.5 -> 0.0)
                        Container(
                          decoration: BoxDecoration(
                            color: isZoomed ? AppColors.accent.withAlpha(51) : Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () async {
                              try {
                                // Simple logic: if zoomed in, zoom out. If zoomed out, zoom in.
                                final newZoom = isZoomed ? 0.0 : 0.6; // 0.6 is a good "reading" zoom
                                await controller.setZoomScale(newZoom);
                              } catch (e) {
                                debugPrint('Error setting zoom: $e');
                              }
                            },
                            icon: Icon(
                              isZoomed ? Icons.zoom_out : Icons.zoom_in,
                              color: isZoomed ? AppColors.accent : Colors.white,
                              size: 28,
                            ),
                            tooltip: 'Zoom x1.5',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
