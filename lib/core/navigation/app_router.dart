import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vector/features/home/presentation/home_screen.dart';
import 'package:vector/features/routes/presentation/routes_screen.dart';
import 'package:vector/features/packages/presentation/packages_screen.dart';
import 'package:vector/features/map/presentation/screens/map_screen.dart';
import 'package:vector/features/main/presentation/main_scaffold.dart';

/// Configuración centralizada de rutas de la aplicación usando GoRouter
class AppRouter {
  static const String home = '/home';
  static const String routes = '/routes';
  static const String packages = '/packages';
  static const String map = '/map';

  /// Crea una instancia de GoRouter con todas las rutas configuradas
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: home,
      debugLogDiagnostics: false,
      routes: [
        // Shell Route para mantener el estado del FloatingNavBar entre tabs
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScaffold(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0: Home
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: home,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: HomeScreen()),
                ),
              ],
            ),

            // Branch 1: Routes
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: routes,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: RoutesScreen()),
                ),
              ],
            ),

            // // Branch 2: Packages
            // StatefulShellBranch(
            //   routes: [
            //     GoRoute(
            //       path: packages,
            //       pageBuilder: (context, state) => const NoTransitionPage(
            //         child: PackagesScreen(),
            //       ),
            //     ),
            //   ],
            // ),

            // // Branch 3: Map
            // StatefulShellBranch(
            //   routes: [
            //     GoRoute(
            //       path: map,
            //       pageBuilder: (context, state) => const NoTransitionPage(
            //         child: MapScreen(),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ],
    );
  }
}
