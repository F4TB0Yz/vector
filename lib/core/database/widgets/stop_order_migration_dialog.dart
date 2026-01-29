import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector/core/database/providers/migration_provider.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';

/// Diálogo para ejecutar la migración de stopOrder.
/// 
/// Este diálogo permite al usuario reparar el orden de las paradas
/// en la base de datos cuando están desordenadas.
class StopOrderMigrationDialog extends StatelessWidget {
  const StopOrderMigrationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MigrationProvider>(
      builder: (context, migrationProvider, _) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: const Text(
            'Reparar Orden de Paradas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta herramienta reordenará todas las paradas de todas las rutas según su fecha de creación.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              if (migrationProvider.isRunning)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else if (migrationProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Error: ${migrationProvider.error}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                )
              else if (migrationProvider.updatedCount != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '✅ ${migrationProvider.updatedCount} paradas actualizadas',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            if (!migrationProvider.isRunning) ...[
              TextButton(
                onPressed: () {
                  migrationProvider.clearState();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
              if (migrationProvider.updatedCount == null)
                ElevatedButton(
                  onPressed: () async {
                    await migrationProvider.runStopOrderMigration();
                    if (context.mounted && migrationProvider.error == null) {
                      showAppToast(
                        context,
                        '${migrationProvider.updatedCount} paradas reordenadas',
                        type: ToastType.success,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Ejecutar'),
                ),
            ],
          ],
        );
      },
    );
  }
}
