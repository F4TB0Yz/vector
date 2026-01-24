import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';

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
          icon: LucideIcons.crosshair,
          onTap: () {
            context.read<MapProvider>().centerOnUserLocation();
          },
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
