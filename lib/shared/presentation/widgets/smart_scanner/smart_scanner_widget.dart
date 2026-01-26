import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vector/core/utils/permission_handler.dart';
import 'package:vector/shared/presentation/widgets/smart_scanner/ar_scanner_painter.dart';
import 'package:vector/shared/presentation/widgets/smart_scanner/detection_confirmation_dialog.dart';
import 'package:vector/shared/presentation/widgets/smart_scanner/scanner_overlay.dart';
import 'package:vibration/vibration.dart';

class SmartScannerWidget extends StatefulWidget {
  final Function(BarcodeCapture) onDetect;
  final VoidCallback? onDispose;

  const SmartScannerWidget({super.key, required this.onDetect, this.onDispose});

  @override
  State<SmartScannerWidget> createState() => _SmartScannerWidgetState();
}

class _SmartScannerWidgetState extends State<SmartScannerWidget>
    with WidgetsBindingObserver {
  late MobileScannerController _controller;
  final ValueNotifier<BarcodeCapture?> _captureNotifier = ValueNotifier(null);
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    final granted = await PermissionHandler.checkCameraPermission();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _isCheckingPermission = false;
      });
    }

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.pdf417,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.aztec,
      ],
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: true,
      autoStart: granted,
    );
  }

  Future<void> _requestPermission() async {
    final granted = await PermissionHandler.requestCameraPermission();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
      });
      if (granted) {
        _controller.start();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized || !_hasPermission) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _controller.stop();
        break;
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        _controller.start();
        break;
    }
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _captureNotifier.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  bool _isProcessing = false;
  Uint8List? _frozenImage;

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing) return;

    _isProcessing = true;

    if (mounted) {
      setState(() {
        _frozenImage = capture.image;
      });
    }

    _captureNotifier.value = capture;

    if (await Vibration.hasVibrator()) {
      Vibration.vibrate();
    }

    // Assuming you have a sound file at this path
    _audioPlayer.play(AssetSource('audio/scanner.wav'));

    if (mounted) {
      _showConfirmationDialog(capture);
    }
  }

  Future<void> _showConfirmationDialog(BarcodeCapture capture) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DetectionConfirmationDialog(
          capture: capture,
          onCancel: () {
            // Resume scanning
            if (mounted) {
              setState(() {
                _isProcessing = false;
                _frozenImage = null; // Unfreeze
              });
              _captureNotifier.value = null;
            }
          },
          onConfirm: () {
            widget.onDetect(capture);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Se requiere permiso de cámara',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                ),
                child: const Text('Habilitar Cámara'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Layer 0: Camera Feed
            MobileScanner(
              controller: _controller,
              onDetect: _handleDetection,
              fit: BoxFit.cover,
            ),

            // Layer 0.5: Frozen Image (If active)
            if (_frozenImage != null)
              Image.memory(
                _frozenImage!,
                fit: BoxFit.cover,
                // On some devices, the captured image might be rotated relative to the preview.
                // MobileScanner usually returns the buffer as is.
                // If it looks rotated, we might need a RotatedBox.
                // For now, assuming standard orientation match or handled by BoxFit.
                gaplessPlayback: true,
              ),

            // Layer 1: AR Overlay
            ValueListenableBuilder<BarcodeCapture?>(
              valueListenable: _captureNotifier,
              builder: (context, capture, child) {
                if (capture == null || capture.barcodes.isEmpty) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  painter: ARScannerPainter(
                    imgSize: capture.size, // Size of the camera image buffer
                    barcodes: capture.barcodes,
                    screenSize: Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Layer 2: UI Controls (Flash, Zoom, Rectangular Guide)
            ScannerOverlay(controller: _controller),
          ],
        );
      },
    );
  }
}
