import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as provider;
import 'package:vector/core/database/database_service.dart';
import 'package:vector/core/di/injection_container.dart' as di;
import 'package:vector/features/auth/domain/repositories/auth_repository.dart';
import 'package:vector/features/auth/domain/usecases/login_usecase.dart';
import 'package:vector/features/auth/domain/usecases/save_credentials.dart';
import 'package:vector/features/auth/presentation/providers/auth_provider.dart';
import 'package:vector/features/map/domain/repositories/map_repository.dart';
import 'package:vector/features/map/domain/usecases/create_stop_from_coordinates.dart';
import 'package:vector/features/map/domain/usecases/optimize_route.dart';
import 'package:vector/features/map/domain/usecases/reverse_geocode_coordinates.dart';
import 'package:vector/features/map/presentation/providers/map_provider.dart';
import 'package:vector/features/routes/data/datasources/routes_preferences_datasource.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import 'package:vector/features/routes/domain/usecases/create_route.dart';
import 'package:vector/features/routes/domain/usecases/get_routes.dart';
import 'package:vector/features/routes/presentation/providers/routes_provider.dart';
import 'package:vector/features/packages/domain/usecases/update_package_status.dart';
import 'package:vector/core/navigation/app_router.dart';

import 'package:vector/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await di.init();

  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN']!);
  HttpOverrides.global = MyHttpOverrides();

  runApp(const MainApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  static final _router = AppRouter.createRouter();

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.Provider<AddStopToRoute>(
          create: (_) => di.sl<AddStopToRoute>(),
          lazy: true,
        ),
        provider.ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authRepository: di.sl<AuthRepository>(),
            loginUseCase: di.sl<LoginUseCase>(),
            saveCredentialsUseCase: di.sl<SaveCredentials>(),
          ),
          lazy: true,
        ),
        provider.ChangeNotifierProvider(
          create: (_) => RoutesProvider(
            getRoutesUseCase: di.sl<GetRoutes>(),
            createRouteUseCase: di.sl<CreateRoute>(),
            prefsDataSource: di.sl<RoutesPreferencesDataSource>(),
            updatePackageStatusUseCase: di.sl<UpdatePackageStatus>(),
          ),
          lazy: true,
        ),
        provider.ChangeNotifierProvider(
          create: (_) => MapProvider(
            mapRepository: di.sl<MapRepository>(),
            reverseGeocodeCoordinatesUseCase: di
                .sl<ReverseGeocodeCoordinates>(),
            createStopFromCoordinatesUseCase: di
                .sl<CreateStopFromCoordinates>(),
            optimizeRouteUseCase: di.sl<OptimizeRoute>(),
          ),
          lazy: true,
        ),
      ],
      child: _InitProvidersWidget(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          routerConfig: _router,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'ES')],
        ),
      ),
    );
  }
}

class _InitProvidersWidget extends StatefulWidget {
  final Widget child;
  const _InitProvidersWidget({required this.child});

  @override
  State<_InitProvidersWidget> createState() => _InitProvidersWidgetState();
}

class _InitProvidersWidgetState extends State<_InitProvidersWidget> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _initialized) return;
      _initialized = true;

      await initializeDateFormatting('es');
      Intl.defaultLocale = 'es';

      await DatabaseService.instance.database;

      if (!mounted) return;
      context.read<AuthProvider>().checkAuthStatus();
      context.read<RoutesProvider>().loadRoutes();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
