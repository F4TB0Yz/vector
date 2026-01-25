import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:vector/core/di/injection_container.dart';
import 'package:vector/features/auth/domain/repositories/auth_repository.dart';
import 'package:vector/features/auth/domain/usecases/login_usecase.dart';
import 'package:vector/features/auth/domain/usecases/save_credentials.dart';
import 'package:vector/features/home/presentation/home_screen.dart';
import 'package:vector/features/map/domain/usecases/optimize_route.dart';
import 'package:vector/shared/presentation/widgets/floating_nav_bar.dart';
import 'package:vector/features/routes/presentation/routes_screen.dart';
import 'package:vector/features/packages/presentation/packages_screen.dart';
import 'package:vector/features/map/presentation/screens/map_screen.dart';
import 'package:vector/shared/presentation/notifications/navbar_notification.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';
import 'package:vector/features/auth/presentation/providers/auth_provider.dart';
import 'package:vector/features/home/presentation/providers/home_provider.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import 'package:vector/features/routes/domain/usecases/create_route.dart';
import 'package:vector/features/routes/domain/usecases/get_routes.dart';
import 'package:vector/features/packages/domain/repositories/jt_package_repository.dart';
import 'package:vector/features/packages/presentation/providers/jt_package_providers.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/map/domain/repositories/map_repository.dart';
import 'package:vector/features/map/domain/usecases/create_stop_from_coordinates.dart';
import 'package:vector/features/map/domain/usecases/reverse_geocode_coordinates.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isNavBarVisible = true; // Estado para controlar visibilidad

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      provider.ChangeNotifierProvider(
        create: (context) =>
            HomeProvider(addStopToRouteUseCase: sl<AddStopToRoute>()),
        child: const HomeScreen(),
      ),
      const RoutesScreen(),
      provider.ChangeNotifierProvider(
        create: (context) =>
            PackagesProvider(repository: sl<JTPackageRepository>()),
        child: const PackagesScreen(),
      ),
      provider.ChangeNotifierProvider(
        create: (context) => MapProvider(
          mapRepository: sl<MapRepository>(),
          reverseGeocodeCoordinatesUseCase: sl<ReverseGeocodeCoordinates>(),
          createStopFromCoordinatesUseCase: sl<CreateStopFromCoordinates>(),
          optimizeRouteUseCase: sl<OptimizeRoute>(),
        ),
        child: const MapScreen(),
      ),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return provider.MultiProvider(
      providers: [
        provider.Provider<AddStopToRoute>(create: (_) => sl<AddStopToRoute>()),
        provider.ChangeNotifierProvider(
          create: (context) => AuthProvider(
            authRepository: sl<AuthRepository>(),
            loginUseCase: sl<LoginUseCase>(),
            saveCredentialsUseCase: sl<SaveCredentials>(),
          )..checkAuthStatus(),
        ),
        provider.ChangeNotifierProvider(
          create: (context) => RoutesProvider(
            getRoutesUseCase: sl<GetRoutes>(),
            createRouteUseCase: sl<CreateRoute>(),
          )..loadRoutes(),
        ),
      ],
      child: Scaffold(
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
              IndexedStack(index: _currentIndex, children: _pages),

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
      ),
    );
  }
}
