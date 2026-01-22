import 'package:flutter/material.dart';
import 'package:vector/shared/presentation/widgets/smart_scanner/smart_scanner_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';

class SharedScannerScreen extends StatelessWidget {
  final void Function(String code) onDetect;

  const SharedScannerScreen({super.key, required this.onDetect});

  @override
  Widget build(BuildContext context) {
    final manualCodeController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.center,
        children: [
          SmartScannerWidget(
            onDetect: (capture) {
              final code = capture.barcodes.first.rawValue;
              if (code != null) {
                onDetect(code);
              }
            },
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: 100.0,
            left: 24,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: manualCodeController,
                      autofocus: false,
                      onSubmitted: onDetect,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ingresar código manualmente...',
                        hintStyle: TextStyle(color: Color(0x96FFFFFF)),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0x64FFFFFF)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.arrowRightCircle,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    onPressed: () {
                      if (manualCodeController.text.isNotEmpty) {
                        final code = manualCodeController.text;
                        onDetect(code);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
