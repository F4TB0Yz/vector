import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vector/shared/presentation/widgets/floating_nav_bar.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart';
import 'package:vector/shared/presentation/widgets/shader_warmup_widget.dart';

/// Scaffold principal que envuelve todas las screens de la aplicación
/// y mantiene el FloatingNavBar persistente entre navegaciones
class MainScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({required this.navigationShell, super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  bool _isNavBarVisible = true;
  bool _canRender = false;

  @override
  void initState() {
    super.initState();
    // Delayed rendering para evitar saturación en frame 0
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _canRender = true);
      }
    });
  }

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    //final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: NotificationListener<Notification>(
          onNotification: (notification) {
            if (notification is NavBarVisibilityNotification) {
              setState(() {
                _isNavBarVisible = notification.isVisible;
              });
              return true;
            } else if (notification is ChangeTabNotification) {
              _onTabTapped(notification.targetIndex);
              return true;
            }
            return false;
          },
          child: Stack(
            children: [
              // Shader warmup solo hasta que se complete
              if (!_canRender) const ShaderWarmupWidget(),

              // Delayed rendering para evitar saturación en frame 0
              if (_canRender) RepaintBoundary(child: widget.navigationShell),

              // Floating Nav Bar - Solo si el teclado está cerrado
              // if (MediaQuery.of(context).viewInsets.bottom == 0)
              //   AnimatedPositioned(
              //     duration: const Duration(milliseconds: 300),
              //     curve: Curves.easeOut,
              //     left: 0,
              //     right: 0,
              //     bottom: _isNavBarVisible ? (bottomPadding + 16) : -125,
              //     child: RepaintBoundary(
              //       child: FloatingNavBar(
              //         currentIndex: widget.navigationShell.currentIndex,
              //         onTap: _onTabTapped,
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}
