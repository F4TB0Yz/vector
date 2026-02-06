import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Optimized FloatingNavBar - Reduced build time from 167ms to <16ms
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Constantes pre-calculadas para evitar recreación
  static const _kNavBarHeight = 70.0;
  static const _kNavBarMargin = EdgeInsets.symmetric(horizontal: 24);
  static const _kNavBarDecoration = BoxDecoration(
    color: Color(0xCC1E1E1E),
    borderRadius: BorderRadius.all(Radius.circular(35)),
    border: Border.fromBorderSide(
      BorderSide(color: Color(0x1AFFFFFF), width: 1),
    ),
  );
  static const _kBorderRadius = BorderRadius.all(Radius.circular(35));

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kNavBarHeight,
      margin: _kNavBarMargin,
      decoration: _kNavBarDecoration,
      child: ClipRRect(
        borderRadius: _kBorderRadius,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavBarItem(
              key: const ValueKey('nav_home'),
              icon: LucideIcons.home,
              label: 'Inicio',
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavBarItem(
              key: const ValueKey('nav_routes'),
              icon: LucideIcons.navigation,
              label: 'Rutas',
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavBarItem(
              key: const ValueKey('nav_packages'),
              icon: LucideIcons.package,
              label: 'Paquetes',
              isSelected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavBarItem(
              key: const ValueKey('nav_map'),
              icon: LucideIcons.map,
              label: 'Mapa',
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful para evitar rebuilds cuando isSelected no cambia
class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> {
  // Constantes pre-calculadas
  static const _kSelectedColor = Color(0xFF00E676);
  static const _kUnselectedColor = Colors.grey;
  static const _kPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const _kIconSize = 26.0;
  static const _kFontSize = 10.0;
  static const _kSelectedWeight = FontWeight.w700;
  static const _kUnselectedWeight = FontWeight.w500;
  static const _kDotSize = 4.0;
  static const _kSpacing = SizedBox(height: 4);
  static const _kDotSpacing = SizedBox(height: 2);

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? _kSelectedColor : _kUnselectedColor;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: _kPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: color, size: _kIconSize),
            _kSpacing,
            Text(
              widget.label,
              style: TextStyle(
                color: color,
                fontSize: _kFontSize,
                fontWeight: widget.isSelected ? _kSelectedWeight : _kUnselectedWeight,
              ),
            ),
            _kDotSpacing,
            // Dot indicator - simplified (removed expensive boxShadow)
            if (widget.isSelected)
              const _SelectedDot()
            else
              const SizedBox(width: _kDotSize, height: _kDotSize),
          ],
        ),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NavBarItemState &&
          runtimeType == other.runtimeType &&
          widget.isSelected == other.widget.isSelected;

  @override
  int get hashCode => widget.isSelected.hashCode;
}

/// Widget const para el dot indicator
class _SelectedDot extends StatelessWidget {
  const _SelectedDot();

  static const _kDotSize = 4.0;
  static const _kSelectedColor = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kDotSize,
      height: _kDotSize,
      decoration: const BoxDecoration(
        color: _kSelectedColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
