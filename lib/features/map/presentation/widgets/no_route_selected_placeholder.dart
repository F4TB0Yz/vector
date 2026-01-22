import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart';

class NoRouteSelectedPlaceholder extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onNavigateToRoutes;

  const NoRouteSelectedPlaceholder({
    super.key,
    required this.isLoading,
    required this.onNavigateToRoutes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3.0,
              )
            else ...[
              Icon(LucideIcons.map, size: 80, color: Colors.grey[700]),
              const SizedBox(height: 24),
              const Text(
                'No hay ruta seleccionada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: Text(
                  'Selecciona una ruta usando el botón de arriba o desde la pantalla de Rutas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Botón para navegar a Rutas
              ElevatedButton.icon(
                onPressed: onNavigateToRoutes,
                icon: const Icon(LucideIcons.list, size: 20),
                label: const Text(
                  'Ver Mis Rutas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4), // Sharp corners
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
