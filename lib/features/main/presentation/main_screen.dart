import 'package:flutter/material.dart';
import 'package:vector/features/home/presentation/home_screen.dart';
import 'package:vector/shared/presentation/widgets/floating_nav_bar.dart';
import 'package:vector/features/routes/presentation/routes_screen.dart';
import 'package:vector/features/packages/presentation/packages_screen.dart';
import 'package:vector/features/map/presentation/screens/map_screen.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart';
import 'package:vector/shared/presentation/widgets/lazy_indexed_stack.dart';
import 'package:vector/shared/presentation/widgets/shader_warmup_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isNavBarVisible = true;
  bool _canRender =
      false; // Delayed rendering para evitar saturación en frame 0

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para renderizar contenido después del primer frame
    // Esto permite que ShaderWarmupWidget compile shaders sin competir por recursos del GPU
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Esperar un frame adicional después del warmup
      Future.delayed(const Duration(milliseconds: 16), () {
        if (mounted) {
          setState(() => _canRender = true);
        }
      });
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    // Páginas
    final pages = [
      const HomeScreen(),
      const RoutesScreen(),
      const PackagesScreen(),
      const MapScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
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
            // Warmup shaders to avoid jank on Map tab
            const ShaderWarmupWidget(),

            // Delayed rendering para evitar saturación en frame 0
            if (_canRender)
              LazyIndexedStack(index: _currentIndex, children: pages)
            else
              const SizedBox.shrink(),

            // Floating Nav Bar - Solo si el teclado está cerrado
            if (MediaQuery.of(context).viewInsets.bottom == 0)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut, // Curva más simple = menos carga
                left: 0,
                right: 0,
                bottom: _isNavBarVisible ? (bottomPadding + 16) : -150,
                child: RepaintBoundary(
                  child: FloatingNavBar(
                    currentIndex: _currentIndex,
                    onTap: _onTabTapped,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
