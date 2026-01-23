import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/auth/presentation/providers/auth_provider.dart';
import 'package:vector/features/packages/presentation/providers/jt_package_providers.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/shared/presentation/widgets/toasts.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';

class PackagesHeader extends ConsumerWidget {
  const PackagesHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRoute = ref.watch(selectedRouteProvider);
    final authState = ref.watch(authProvider);
    final jtPackagesState = ref.watch(jtPackagesProvider);

    final bool isSessionActive = authState.value?.isSome() ?? false;
    final bool isLoading = jtPackagesState.isLoading;
    final bool isDownloadEnabled = isSessionActive && !isLoading;

    // Escuchar cambios en jtPackagesState para mostrar resultado de importación
    ref.listen<AsyncValue<List<JTPackage>>>(jtPackagesProvider, (
      previous,
      next,
    ) {
      // Solo mostrar toast si cambió de loading a data/error
      if (previous?.isLoading == true) {
        next.when(
          data: (packages) {
            if (packages.isNotEmpty && selectedRoute != null) {
              showAppToast(
                context,
                '✅ ${packages.length} paquetes importados a ${selectedRoute.name}',
                type: ToastType.success,
              );
            }
          },
          loading: () {},
          error: (error, _) {
            showAppToast(
              context,
              'Error al importar: $error',
              type: ToastType.error,
            );
          },
        );
      }
    });

    void handleImportClick() {
      if (isLoading) {
        showAppToast(
          context,
          'Ya hay una importación en curso...',
          type: ToastType.info,
        );
        return;
      }

      if (!isSessionActive) {
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

      ref.read(jtPackagesProvider.notifier).importPackages();
      showAppToast(context, 'Importando paquetes...', type: ToastType.info);
    }

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
              _RouteSelector(selectedRoute: selectedRoute),
              IconButton(
                tooltip: !isSessionActive
                    ? 'Inicia sesión en J&T para importar'
                    : selectedRoute == null
                    ? 'Selecciona una ruta para importar'
                    : 'Importar Paquetes de J&T a ${selectedRoute.name}',
                onPressed: handleImportClick,
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

class _RouteSelector extends ConsumerWidget {
  final RouteEntity? selectedRoute;

  const _RouteSelector({required this.selectedRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(routesProvider);

    return routesAsync.when(
      data: (routes) {
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
            ref.read(selectedRouteProvider.notifier).state = route;
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
      },
      loading: () => const SizedBox(width: 48),
      error: (_, __) => const Icon(LucideIcons.alertCircle, color: Colors.red),
    );
  }
}
