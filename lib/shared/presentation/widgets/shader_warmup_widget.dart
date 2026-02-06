import 'package:flutter/material.dart';
import 'package:vector/core/theme/app_colors.dart';

/// Forces the GPU to compile shaders for specific effects (Shadows, Glows)
/// by rendering them with minimal opacity. This prevents jank (PipelineVK::Create)
/// when these effects are first shown on screen (e.g., in the Map tab).
class ShaderWarmupWidget extends StatelessWidget {
  const ShaderWarmupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Warmup NextStopCard Shadow (Blur 20)
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),
          // Warmup MapControls Glow (Blur 12, Spread 2)
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
