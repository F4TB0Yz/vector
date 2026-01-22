import 'package:flutter/material.dart';
import 'package:vector/features/home/presentation/home_screen.dart';
import 'package:vector/shared/presentation/widgets/floating_nav_bar.dart';
import 'package:vector/features/routes/presentation/routes_screen.dart';
import 'package:vector/features/packages/presentation/packages_screen.dart';
import 'package:vector/features/map/presentation/screens/map_screen.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isNavBarVisible = true; // Estado para controlar visibilidad

  final List<Widget> _pages = [
    const HomeScreen(),
    const RoutesScreen(),
    const PackagesScreen(),
    const MapScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.black, // O el color de fondo de tu tema
      body: NotificationListener<Notification>(
        onNotification: (notification) {
          if (notification is NavBarVisibilityNotification) {
            setState(() {
              _isNavBarVisible = notification.isVisible;
            });
            return true;
          } else if (notification is ChangeTabNotification) {
            setState(() {
              _currentIndex = notification.targetIndex;
            });
            return true;
          }
          return false;
        },
        child: Stack(
          children: [
            // IndexedStack mantiene el estado de las páginas vivas
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            
            // Floating Navy Bar ubicada en la parte inferior
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 0,
              right: 0,
              // Si es visible, se posiciona arriba del padding del sistema + 16px de margen
              // Si no, se esconde completamente (-150 px para asegurar)
              bottom: _isNavBarVisible ? (bottomPadding + 16) : -150, 
              child: FloatingNavBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


