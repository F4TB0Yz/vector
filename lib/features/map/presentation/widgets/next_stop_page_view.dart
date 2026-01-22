import 'package:flutter/material.dart';
import 'package:vector/features/map/presentation/widgets/next_stop_card.dart';
import 'package:vector/features/routes/domain/entities/route_entity.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart'; // For NavBarVisibilityNotification

class NextStopPageView extends StatelessWidget {
  final PageController pageController;
  final RouteEntity selectedRoute;
  final bool showNextStopCard;
  final VoidCallback onCloseNextStopCard;

  const NextStopPageView({
    super.key,
    required this.pageController,
    required this.selectedRoute,
    required this.showNextStopCard,
    required this.onCloseNextStopCard,
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
                    ],
                  ),
                ),
              );
            },
            child: NextStopCard(
              stopNumber: "PARADA ${stop.stopOrder}",
              timeAway: "A ${3 + index * 5} MIN", // This is hardcoded example data, should come from stop
              address: stop.address,
              packageType: "Paquete", // This is hardcoded, should come from stop
              weight: "N/A", // This is hardcoded, should come from stop
              isPriority: index == 0,
              note: null, // This is hardcoded, should come from stop
              onClose: () {
                onCloseNextStopCard();
                const NavBarVisibilityNotification(true).dispatch(context);
              },
            ),
          );
        },
      ),
    );
  }
}
