import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';

class ConfirmAddStopDialog extends ConsumerWidget {
  final StopCreationRequest request;

  const ConfirmAddStopDialog({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    // Watch the provider to rebuild when geocoding finishes
    final currentRequest = ref.watch(
      mapProvider.select((state) => state.stopCreationRequest),
    );

    // Use current request from provider if available, otherwise use the initial one
    final displayRequest = currentRequest ?? request;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24).withOpacity(0.85),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nueva Parada',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Content
                  displayRequest.isGeocoding
                      ? _buildGeocodingIndicator()
                      : _buildAddressContent(textTheme, displayRequest),
                  const SizedBox(height: 24),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: () {
                          ref.read(mapProvider.notifier).cancelStopCreation();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Confirm button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: displayRequest.isGeocoding
                              ? null
                              : const LinearGradient(
                                  colors: [AppColors.accent, Color(0xFF00CC5E)],
                                ),
                          boxShadow: displayRequest.isGeocoding
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.3),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: displayRequest.isGeocoding
                                ? null
                                : () {
                                    ref
                                        .read(mapProvider.notifier)
                                        .confirmStopCreation();
                                  },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Text(
                                'Confirmar',
                                style: TextStyle(
                                  color: displayRequest.isGeocoding
                                      ? Colors.grey
                                      : Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildGeocodingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Obteniendo dirección...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressContent(
    TextTheme textTheme,
    StopCreationRequest displayRequest,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Desea crear una nueva parada en esta ubicación?',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppColors.accent.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.mapPin, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayRequest.suggestedAddress ??
                      'No se pudo obtener la dirección.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
