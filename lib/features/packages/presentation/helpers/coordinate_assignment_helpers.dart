import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector/features/packages/presentation/pages/coordinate_assignment_screen.dart';
import 'package:vector/features/packages/presentation/providers/coordinate_assignment_provider.dart';
import 'package:vector/core/di/injection_container.dart';
import 'package:vector/features/packages/domain/usecases/update_package_coordinates.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';

/// Helper class for coordinate assignment functionality
class CoordinateAssignmentHelpers {
  static Future<void> openCoordinateAssignment(BuildContext context) async {
    final routesProvider = context.read<RoutesProvider>();
    final selectedRoute = routesProvider.selectedRoute;

    if (selectedRoute == null) {
      showAppToast(
        context,
        'Selecciona una ruta primero',
        type: ToastType.warning,
      );
      return;
    }

    // Extraer TODOS los paquetes (permitir editar coordenadas de cualquier paquete)
    final packages = selectedRoute.stops
        .map((stop) => stop.package)
        .toList();

    if (packages.isEmpty) {
      showAppToast(
        context,
        'No hay paquetes en esta ruta',
        type: ToastType.info,
      );
      return;
    }

    if (!context.mounted) return;

    // Navegar a la pantalla de asignación con provider
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => CoordinateAssignmentProvider(
            updatePackageCoordinatesUseCase: sl<UpdatePackageCoordinates>(),
            packagesWithoutCoordinates: packages,
          ),
          child: const CoordinateAssignmentScreen(),
        ),
      ),
    );

    // Recargar rutas y actualizar mapa después de asignar coordenadas
    if (context.mounted) {
      routesProvider.loadRoutes();
      
      // Intentar actualizar el mapa principal solo si está disponible
      try {
        context.read<MapProvider>().loadActiveRoute();
      } catch (e) {
        debugPrint('MapProvider no disponible en este contexto: $e');
      }
    }
  }
}
