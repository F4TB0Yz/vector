import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/core/utils/permission_handler.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';

class MapControlsColumn extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final mapProvider = context.watch<MapProvider>();
    final mapState = mapProvider.state;
    final isOptimizing = mapState.isOptimizing;
    final isPermanentlyDenied = mapState.locationPermission == geo.LocationPermission.deniedForever;

    return Column(
      children: [
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
          icon: LucideIcons.zap,
          onTap: isOptimizing
              ? null
              : () {
                  final routesProvider = context.read<RoutesProvider>();
                  context.read<MapProvider>().optimizeCurrentRoute(routesProvider);
                },
          isActive: isOptimizing,
          color: isOptimizing ? Colors.orange : AppColors.primary,
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: LucideIcons.rotateCcw,
          onTap: () {
            context.read<MapProvider>().toggleReturnToStart(
              !mapState.returnToStart,
            );
          },
          isActive: mapState.returnToStart,
          color: mapState.returnToStart ? Colors.green : null,
        ),
        const SizedBox(height: 24),
        _MapControlButton(
          icon: isPermanentlyDenied ? LucideIcons.alertTriangle : LucideIcons.crosshair,
          onTap: isPermanentlyDenied 
              ? () => PermissionHandler.openSettings()
              : () => context.read<MapProvider>().centerOnUserLocation(),
          color: isPermanentlyDenied ? Colors.red : (mapState.isFollowMode ? AppColors.accent : null),
          isActive: isPermanentlyDenied || mapState.isFollowMode,
          showGlow: mapState.isFollowMode,
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: LucideIcons.plus,
          onTap: () {
            context.read<MapProvider>().zoomIn();
          },
        ),
        const SizedBox(height: 8),
        _MapControlButton(
          icon: LucideIcons.minus,
          onTap: () {
            context.read<MapProvider>().zoomOut();
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
  final Color? color;
  final bool showGlow;

  const _MapControlButton({
    required this.icon,
    this.onTap,
    this.isActive = false,
    this.color,
    this.showGlow = false,
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
            color: isActive
                ? (color ?? AppColors.primary)
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: showGlow ? AppColors.accent : Colors.white.withAlpha(25),
              width: showGlow ? 2 : 1,
            ),
            boxShadow: [
              if (showGlow)
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 4),
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
