import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

class MapControlsColumn extends ConsumerWidget {
  final bool showNextStopCard;
  final bool showPackageList;
  final VoidCallback onToggleNextStopCard;
  final VoidCallback onTogglePackageList;

  const MapControlsColumn({
    super.key,
    required this.showNextStopCard,
    required this.showPackageList,
    required this.onToggleNextStopCard,
    required this.onTogglePackageList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Route Selector
        Consumer(
          builder: (context, ref, child) {
            final routesAsync = ref.watch(routesProvider);
            return routesAsync.when(
              data: (routes) {
                if (routes.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _MapControlButton(
                  icon: LucideIcons.map,
                  isActive: true,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF1E1E1E),
                      builder: (context) => ListView.builder(
                        itemCount: routes.length,
                        itemBuilder: (context, index) {
                          final route = routes[index];
                          return ListTile(
                            title: Text(
                              route.name,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            onTap: () {
                              ref
                                  .read(
                                    selectedRouteProvider.notifier,
                                  )
                                  .state = route;
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const _MapControlButton(
                icon: LucideIcons.map,
                onTap: null,
              ),
              error: (_, __) => const _MapControlButton(
                icon: LucideIcons.alertCircle,
                onTap: null,
                isActive: true,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: LucideIcons.layers,
          onTap: onToggleNextStopCard,
          isActive: showNextStopCard,
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: LucideIcons.list,
          onTap: onTogglePackageList,
          isActive: showPackageList,
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: LucideIcons.crosshair,
          onTap: () {
            ref.read(mapProvider.notifier).centerOnUserLocation();
          },
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: LucideIcons.plus,
          onTap: () {
            ref.read(mapProvider.notifier).zoomIn();
          },
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: LucideIcons.minus,
          onTap: () {
            ref.read(mapProvider.notifier).zoomOut();
          },
        ),
      ],
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;

  const _MapControlButton({
    required this.icon,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withAlpha(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(76),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.black : Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
