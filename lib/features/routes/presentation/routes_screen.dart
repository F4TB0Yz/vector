import 'package:flutter/material.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/routes/presentation/widgets/route_card.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  int _selectedIndex = 0;

  final List<String> _filters = ["TODAS", "ACTIVA", "EN ESPERA"];

  @override
  Widget build(BuildContext context) {
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
                        'Rutas Disponibles',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                       Text(
                        'Arma las ruta a tu manera',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                   ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement filter functionality
                    },
                    icon: const Icon(
                      Icons.filter_list,
                      color: Colors.white,
                    ),
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
                          borderRadius: BorderRadius.circular(6), // Sharp corners as per SKILL
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
              child: ListView(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 100.0, // Space for FloatingNavBar
                ),
                children: const [
                  RouteCard(
                    routeId: 'RT-4092',
                    status: 'READY',
                    estTime: '4h 15m',
                    stops: 42,
                    distance: 18.5,
                  ),
                   SizedBox(height: 16),
                  RouteCard(
                     routeId: 'RT-4093',
                    status: 'ACTIVE',
                    estTime: '2h 10m',
                    stops: 24,
                    distance: 12.0,
                  ),
                   SizedBox(height: 16),
                   RouteCard(
                     routeId: 'RT-4094',
                    status: 'COMPLETED',
                    estTime: '5h 30m',
                    stops: 55,
                    distance: 25.4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
