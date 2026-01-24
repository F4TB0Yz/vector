import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/auth/presentation/providers/auth_provider.dart';
import 'package:vector/features/packages/presentation/providers/jt_package_providers.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';

class PackagesHeader extends StatelessWidget {
  const PackagesHeader({super.key});

  Future<void> _handleImportClick(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final routesProvider = context.read<RoutesProvider>();
    final selectedRoute = routesProvider.selectedRoute;
    final packagesProvider = context.read<PackagesProvider>();

    if (packagesProvider.isLoading) {
      showAppToast(
        context,
        'Ya hay una importación en curso...',
        type: ToastType.info,
      );
      return;
    }

    if (!authProvider.isAuthenticated) {
      showAppToast(
        context,
        'Inicia sesión en J&T para importar paquetes',
        type: ToastType.warning,
      );
      return;
    }

    if (selectedRoute == null) {
      showAppToast(
        context,
        'Selecciona una ruta para importar los paquetes',
        type: ToastType.warning,
      );
      return;
    }

    showAppToast(
      context,
      'Importando paquetes...',
      type: ToastType.info,
      duration: const Duration(seconds: 1),
    );

    await packagesProvider.importPackages(
      selectedRoute: selectedRoute,
      addStopUseCase: context.read<AddStopToRoute>(),
      onLogout: () {
        authProvider.logout();
      },
      onRouteRefreshed: () {
        routesProvider.loadRoutes();
      },
    );

    if (context.mounted) {
      if (packagesProvider.error != null) {
         showAppToast(
          context,
          'Error al importar: ${packagesProvider.error}',
          type: ToastType.error,
        );
      } else {
         showAppToast(
          context,
          'Importación completada',
          type: ToastType.success,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routesProvider = context.watch<RoutesProvider>();
    final authProvider = context.watch<AuthProvider>();
    final packagesProvider = context.watch<PackagesProvider>(); // Only need state for button (using watch below if needed for UI update)
    final isLoading = context.watch<PackagesProvider>().isLoading; // Listen to loading

    final selectedRoute = routesProvider.selectedRoute;
    final bool isSessionActive = authProvider.isAuthenticated;
    final bool isDownloadEnabled = isSessionActive && !isLoading;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paradas de la Ruta',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedRoute?.name ?? 'Ninguna ruta seleccionada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              _RouteSelector(),
              IconButton(
                tooltip: !isSessionActive
                    ? 'Inicia sesión en J&T para importar'
                    : selectedRoute == null
                    ? 'Selecciona una ruta para importar'
                    : 'Importar Paquetes de J&T a ${selectedRoute.name}',
                onPressed: () => _handleImportClick(context),
                icon: Icon(
                  LucideIcons.packageSearch,
                  color: isDownloadEnabled
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final routesProvider = context.watch<RoutesProvider>();
    final routes = routesProvider.routes;
    final selectedRoute = routesProvider.selectedRoute;
    final isLoading = routesProvider.isLoading;

    if (isLoading) return const SizedBox(width: 48);
    // if error?

    final todayRoutes = routes
        .where((route) => DateUtils.isSameDay(route.date, DateTime.now()))
        .toList();

    if (todayRoutes.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<RouteEntity>(
      tooltip: selectedRoute?.name ?? 'Seleccionar Ruta',
      icon: Icon(
        LucideIcons.map,
        color: selectedRoute != null ? AppColors.primary : Colors.grey,
      ),
      color: const Color(0xFF2C2C35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (route) {
        context.read<RoutesProvider>().selectRoute(route);
        showAppToast(
          context,
          'Ruta: ${route.name}',
          type: ToastType.success,
        );
      },
      itemBuilder: (context) => todayRoutes.map((route) {
        return PopupMenuItem<RouteEntity>(
          value: route,
          child: Text(route.name, style: TextStyle(color: Colors.white)),
        );
      }).toList(),
    );
  }
}
