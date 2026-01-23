import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/packages/presentation/widgets/package_card.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart';

class PackageListOverlay extends StatelessWidget {
  final RouteEntity selectedRoute;
  final bool showPackageList;
  final VoidCallback onClosePackageList;

  const PackageListOverlay({
    super.key,
    required this.selectedRoute,
    required this.showPackageList,
    required this.onClosePackageList,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutBack,
      left: 0,
      right: 0,
      bottom: showPackageList ? 0 : -600,
      height: 500,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xF21E1E1E),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
          border: Border(
            top: BorderSide(color: Color(0x19FFFFFF)),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x7F000000),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Paradas de ${selectedRoute.name}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon( // Added const here
                      LucideIcons.x,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      onClosePackageList();
                      const NavBarVisibilityNotification(
                        true,
                      ).dispatch(context);
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withAlpha(25)),

            // Lista
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: selectedRoute.stops.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final stop = selectedRoute.stops[index];
                  return PackageCard(
                    package: stop.package,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
