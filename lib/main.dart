import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:vector/core/database/database_service.dart';
import 'package:vector/core/database/seed_data.dart';
import 'package:vector/features/main/presentation/main_screen.dart';
import 'package:vector/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  Intl.defaultLocale = 'es';
  debugPrint('Locale initialized for es');

  // Cargar variables de entorno
  await dotenv.load(fileName: '.env');
  
  // Configurar Mapbox
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN']!);

  // Inicializar base de datos
  debugPrint('Initializing database...');
  await DatabaseService.instance.database;
  debugPrint('Database initialized successfully');

  // Poblar con datos de ejemplo en modo debug
  if (kDebugMode) {
    debugPrint('Seeding database with example data...');
    await SeedData.seed();
    debugPrint('Database seeded successfully');
  }

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
    );
  }
}
