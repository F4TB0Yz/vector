import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/packages/presentation/widgets/package_card.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'providers/jt_package_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  int _selectedIndex = 0;

  final List<String> _filters = ["TODAS", "PENDIENTE", "ENTREGADO", "FALLIDO"];

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(jtPackagesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Paquetes',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                       Text(
                        'Gestión de entregas',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                   ),
                  Row(
                    children: [
                      // Route Selector
                      Consumer(
                        builder: (context, ref, child) {
                          final routesAsync = ref.watch(routesProvider);
                          return routesAsync.when(
                            data: (routes) {
                              if (routes.isEmpty) return const SizedBox.shrink();
                              return PopupMenuButton<RouteEntity>(
                                tooltip: 'Seleccionar Ruta',
                                icon: const Icon(LucideIcons.map, color: AppColors.primary),
                                color: const Color(0xFF2C2C35),
                                onSelected: (route) {
                                  // TODO: Handle route selection (filter packages or set active)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Ruta seleccionada: ${route.name}'),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                                itemBuilder: (context) => routes.map((route) {
                                  return PopupMenuItem<RouteEntity>(
                                    value: route,
                                    child: Text(
                                      route.name,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(jtPackagesProvider.notifier).importPackages();
                        },
                        icon: const Icon(
                          LucideIcons.downloadCloud,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Selectors
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF2C2C35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          _filters[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[400],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            
            Expanded(
              child: packagesAsync.when(
                data: (packages) {
                  if (packages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.package, size: 64, color: Colors.grey[800]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay paquetes cargados',
                            style: TextStyle(color: Colors.grey[400], fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(jtPackagesProvider.notifier).importPackages();
                            },
                            icon: const Icon(LucideIcons.inbox, color: Colors.black),
                            label: const Text(
                              'IMPORTAR PAQUETES J&T',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // TODO: Implement filtering based on _selectedIndex if needed in future
                  // For now showing all fetched
                  
                  return ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: 100.0,
                    ),
                    itemCount: packages.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final package = packages[index];
                      // Map J&T status to UI string if needed, or use raw for now
                      final statusString = package.taskStatus == 3 ? 'PENDIENTE' : 'ESTADO ${package.taskStatus}';
                      
                      return PackageCard(
                        trackingId: package.waybillNo,
                        status: statusString, 
                        address: package.address,
                        customerName: package.receiverName,
                        timeWindow: package.phone, // Using phone as secondary info for now
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar paquetes',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString().replaceAll('Exception:', ''),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(jtPackagesProvider.notifier).importPackages(),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
