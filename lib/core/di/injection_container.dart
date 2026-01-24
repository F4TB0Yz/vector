import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:vector/core/database/database_service.dart';

// Auth
import 'package:vector/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:vector/features/auth/data/datasources/jt_auth_service.dart';
import 'package:vector/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vector/features/auth/domain/repositories/auth_repository.dart';
import 'package:vector/features/auth/domain/usecases/get_saved_credentials.dart';
import 'package:vector/features/auth/domain/usecases/login_usecase.dart';
import 'package:vector/features/auth/domain/usecases/save_credentials.dart';

// Map
import 'package:vector/features/map/data/datasources/geocoding_remote_datasource.dart';
import 'package:vector/features/map/data/datasources/map_datasource.dart';
import 'package:vector/features/map/data/datasources/route_remote_datasource.dart';
import 'package:vector/features/map/data/datasources/stop_local_datasource.dart';
import 'package:vector/features/map/data/repositories/geocoding_repository_impl.dart';
import 'package:vector/features/map/data/repositories/map_repository_impl.dart';
import 'package:vector/features/map/data/repositories/stop_repository_impl.dart';
import 'package:vector/features/map/domain/repositories/geocoding_repository.dart';
import 'package:vector/features/map/domain/repositories/map_repository.dart';
import 'package:vector/features/map/domain/repositories/stop_repository.dart';
import 'package:vector/features/map/domain/usecases/create_stop.dart';
import 'package:vector/features/map/domain/usecases/create_stop_from_coordinates.dart';
import 'package:vector/features/map/domain/usecases/delete_stop.dart';
import 'package:vector/features/map/domain/usecases/get_stops_by_route.dart';
import 'package:vector/features/map/domain/usecases/reorder_stops.dart';
import 'package:vector/features/map/domain/usecases/reverse_geocode_coordinates.dart';
import 'package:vector/features/map/domain/usecases/update_stop.dart';

// Routes
import 'package:vector/features/routes/data/datasources/routes_local_datasource.dart';
import 'package:vector/features/routes/data/repositories/routes_repository_impl.dart';
import 'package:vector/features/routes/domain/repositories/routes_repository.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import 'package:vector/features/routes/domain/usecases/create_route.dart';
import 'package:vector/features/routes/domain/usecases/get_routes.dart';

// Packages
import 'package:vector/features/packages/data/datasources/jt_packages_datasource.dart';
import 'package:vector/features/packages/data/repositories/jt_package_repository_impl.dart';
import 'package:vector/features/packages/domain/repositories/jt_package_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ! Features - Auth
  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SaveCredentials(sl()));
  sl.registerLazySingleton(() => GetSavedCredentials(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );

  // DataSources
  sl.registerLazySingleton(() => JtAuthService(sl()));
  sl.registerLazySingleton(() => AuthLocalDataSource());

  // ! Features - Map
  // UseCases
  sl.registerLazySingleton(() => GetStopsByRoute(sl()));
  sl.registerLazySingleton(() => CreateStop(sl()));
  sl.registerLazySingleton(() => UpdateStop(sl()));
  sl.registerLazySingleton(() => DeleteStop(sl()));
  sl.registerLazySingleton(() => ReorderStops(sl()));
  sl.registerLazySingleton(() => CreateStopFromCoordinates(sl()));
  sl.registerLazySingleton(() => ReverseGeocodeCoordinates(sl()));

  // Repository
  sl.registerLazySingleton<MapRepository>(
    () => MapRepositoryImpl(remoteDataSource: sl(), routeRemoteDataSource: sl()),
  );
  sl.registerLazySingleton<StopRepository>(
    () => StopRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<GeocodingRepository>(
    () => GeocodingRepositoryImpl(remoteDataSource: sl()),
  );

  // DataSources
  sl.registerLazySingleton<MapDataSource>(
    () => MapLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton(() => RouteRemoteDataSource());
  sl.registerLazySingleton(() => GeocodingRemoteDataSource());
  sl.registerLazySingleton(() => StopLocalDataSource(sl()));

  // ! Features - Routes
  // UseCases
  sl.registerLazySingleton(() => GetRoutes(sl()));
  sl.registerLazySingleton(() => CreateRoute(sl()));
  sl.registerLazySingleton(() => AddStopToRoute(sl()));

  // Repository
  sl.registerLazySingleton<RoutesRepository>(
    () => RoutesRepositoryImpl(sl()),
  );

  // DataSources
  sl.registerLazySingleton<RoutesLocalDataSource>(
    () => RoutesLocalDataSourceImpl(sl()),
  );

  // ! Features - Packages
  // Repository
  sl.registerLazySingleton<JTPackageRepository>(
    () => JTPackageRepositoryImpl(sl(), sl()),
  );

  // DataSources
  sl.registerLazySingleton<JTPackagesDataSource>(
    () => JTPackagesDataSourceImpl(sl()),
  );

  // ! Core
  sl.registerLazySingleton(() => DatabaseService.instance);
  sl.registerLazySingleton(() => Dio());
}
