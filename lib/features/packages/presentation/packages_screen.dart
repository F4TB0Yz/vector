import 'package:flutter/material.dart';
import 'package:vector/core/theme/app_colors.dart';
import 'package:vector/features/packages/presentation/widgets/package_card.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  int _selectedIndex = 0;

  final List<String> _filters = ["TODAS", "PENDIENTE", "ENTREGADO", "FALLIDO"];

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
                  IconButton(
                    onPressed: () {
                      // TODO: Implement search/scan functionality
                    },
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
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
              child: ListView(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 100.0, // Space for FloatingNavBar
                ),
                children: const [
                  PackageCard(
                    trackingId: 'VEC-8821',
                    status: 'PENDIENTE',
                    address: 'Cra 15 #4-20, Fusagasugá',
                    customerName: 'Juan Pérez',
                    timeWindow: 'Hoy, 2:00 PM - 4:00 PM',
                  ),
                   SizedBox(height: 16),
                  PackageCard(
                    trackingId: 'VEC-8822',
                    status: 'ENTREGADO',
                    address: 'Calle 8 #12-45, Fusagasugá',
                    customerName: 'María Rodríguez',
                    timeWindow: 'Entregado a las 10:30 AM',
                  ),
                   SizedBox(height: 16),
                   PackageCard(
                    trackingId: 'VEC-8823',
                    status: 'EN RUTA',
                    address: 'Av Las Palmas #30-10, Fusagasugá',
                    customerName: 'Carlos Gómez',
                    timeWindow: 'Llegada est. 15 min',
                  ),
                   SizedBox(height: 16),
                   PackageCard(
                    trackingId: 'VEC-8824',
                    status: 'FALLIDO',
                    address: 'Vereda El Placer, Finca La Esperanza',
                    customerName: 'Ana Martínez',
                    timeWindow: 'Intento fallido 11:00 AM',
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
