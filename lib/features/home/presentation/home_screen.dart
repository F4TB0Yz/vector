import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vector/features/home/presentation/widgets/active_route_card.dart';

import 'package:vector/features/home/presentation/widgets/home_header.dart';
import 'package:vector/features/home/presentation/widgets/home_action_buttons.dart';
import 'package:vector/features/home/presentation/widgets/home_stats_widget.dart';
import 'package:vector/features/home/presentation/widgets/floating_scan_button.dart';
import 'package:vector/features/routes/presentation/widgets/add_route_dialog.dart';
import 'package:vector/shared/presentation/widgets/smart_scanner/smart_scanner_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              SmartScannerWidget(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    debugPrint('Barcode found! ${barcode.rawValue}');
                  }
                  // Here we would handle the result and pop
                  // For now just pop
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Código detectado: ${barcodes.first.rawValue}",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom:
            false, // Permitir que el contenido fluya detrás de la navbar si es necesario, pero usaremos padding
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 120, // Espacio para la FloatingNavBar
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),

              const SizedBox(height: 24),

              ActiveRouteCard(deliveredCount: 12, totalCount: 45),

              const SizedBox(height: 20),

              const HomeStatsWidget(deliveredCount: 12),

              const SizedBox(height: 20),

              HomeActionButtons(
                onScanTap: () => _openScanner(context),
                onNewRouteTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AddRouteDialog(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90), // Lift above FloatingNavBar
        child: FloatingScanButton(onTap: () => _openScanner(context)),
      ),
    );
  }
}
