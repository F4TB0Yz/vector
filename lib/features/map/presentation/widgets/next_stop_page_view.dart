import 'package:flutter/material.dart';
import 'package:vector/features/map/presentation/widgets/next_stop_card.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart'; // For NavBarVisibilityNotification
import 'package:vector/features/map/domain/entities/stop_entity.dart'; // Import for StopEntity

class NextStopPageView extends StatelessWidget {
  final PageController pageController;
  final RouteEntity selectedRoute;
  final bool showNextStopCard;
  final VoidCallback onCloseNextStopCard;
  final void Function(StopEntity stop)? onDelivered; // New callback
  final void Function(StopEntity stop)? onFailed; // New callback

  const NextStopPageView({
    super.key,
    required this.pageController,
    required this.selectedRoute,
    required this.showNextStopCard,
    required this.onCloseNextStopCard,
    this.onDelivered, // Add to constructor
    this.onFailed, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutBack,
      left: 0,
      right: 0,
      bottom: showNextStopCard ? 30 : -500,
      height: 350,
      child: PageView.builder(
        controller: pageController,
        padEnds: false,
        physics: const PageScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // Add this line
        itemCount: selectedRoute.stops.length,
        itemBuilder: (context, index) {
          final stop = selectedRoute.stops[index];

          return AnimatedBuilder(
            animation: pageController,
            builder: (context, child) {
              double value = 0.0;
              if (pageController.position.haveDimensions) {
                value = index.toDouble() - (pageController.page ?? 0);
                value = (value * 0.4).clamp(-1, 1);
              }

              final scale = 1.0 - (value.abs() * 0.1);
              final opacity = value.abs().clamp(0.0, 1.0);

              return Center(
                child: Transform.scale(
                  scale: scale,
                  child: Stack(
                    children: [
                      child!,
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(
                                (255 * opacity * 1.3).clamp(0, 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(
                                4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: NextStopCard(
              stop: stop, // Pass the StopEntity object
              onClose: () {
                onCloseNextStopCard();
                const NavBarVisibilityNotification(true).dispatch(context);
              },
              onDelivered: onDelivered, // Pass the onDelivered callback
              onFailed: onFailed, // Pass the onFailed callback
            ),
          );
        },
      ),
    );
  }
}
