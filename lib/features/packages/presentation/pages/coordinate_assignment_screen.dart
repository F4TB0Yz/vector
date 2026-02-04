import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/packages/presentation/providers/coordinate_assignment_provider.dart';
import 'package:vector/features/packages/presentation/pages/fullscreen_map_picker_screen.dart';
import 'package:vector/features/packages/presentation/widgets/package_info_compact_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Pantalla para asignar coordenadas a paquetes sin ubicación
class CoordinateAssignmentScreen extends StatelessWidget {
  const CoordinateAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CoordinateAssignmentProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E24),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.x, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Asignar Ubicación',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Contador de progreso
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.currentIndex + 1}/${provider.totalPackages}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Información del paquete
                        PackageInfoCompactCard(
                          package: provider.currentPackage,
                        ),
                        const SizedBox(height: 16),

                        // Instrucciones
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: 20,
                                color: AppColors.accent,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Toca el mapa para seleccionar la ubicación del paquete',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botón para abrir mapa en pantalla completa
                        Material(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => FullscreenMapPickerScreen(
                                    initialPosition: provider.selectedCoordinates ?? 
                                                   provider.currentPackage.coordinates,
                                  ),
                                ),
                              );

                              if (result != null && result is Position) {
                                provider.updateSelectedCoordinates(result);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    LucideIcons.map,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'ABRIR MAPA',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Toca aquí para seleccionar la ubicación',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Coordenadas seleccionadas (feedback visual)
                        if (provider.hasSelectedCoordinates) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.checkCircle,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ubicación seleccionada: ${provider.selectedCoordinates!.lat.toStringAsFixed(6)}, ${provider.selectedCoordinates!.lng.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Mensaje de error si existe
                        if (provider.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.alertCircle,
                                  size: 16,
                                  color: Color(0xFFFF5252),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFFF5252),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Barra de acciones inferior
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Botón Anterior
                      if (provider.currentIndex > 0)
                        Expanded(
                          child: _ActionButton(
                            label: 'ANTERIOR',
                            icon: LucideIcons.chevronLeft,
                            onPressed: provider.previousPackage,
                            color: Colors.white.withValues(alpha: 0.6),
                            outlined: true,
                          ),
                        ),
                      
                      if (provider.currentIndex > 0) const SizedBox(width: 12),

                      // Botón Guardar y Continuar
                      Expanded(
                        flex: 2,
                        child: _ActionButton(
                          label: provider.isLastPackage
                              ? 'GUARDAR'
                              : 'GUARDAR Y CONTINUAR',
                          icon: provider.isLastPackage
                              ? LucideIcons.check
                              : LucideIcons.chevronRight,
                          iconRight: !provider.isLastPackage,
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  final success = await provider.saveAndContinue();
                                  if (success && provider.isLastPackage && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          color: AppColors.accent,
                          outlined: false,
                          isLoading: provider.isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Botón de acción reutilizable
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final bool outlined;
  final bool iconRight;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.outlined = false,
    this.iconRight = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: outlined ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.5),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!iconRight) ...[
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (iconRight) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18, color: color),
                  ],
                ],
              ),
      ),
    );
  }
}
