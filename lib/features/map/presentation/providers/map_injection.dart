import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector/core/database/database_service.dart';
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

// Database Service Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});

// Map Data Source Provider
final mapDataSourceProvider = Provider<MapDataSource>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return MapLocalDataSourceImpl(databaseService);
});

// Route Remote Data Source Provider (Mapbox Directions API)
final routeRemoteDataSourceProvider = Provider<RouteRemoteDataSource>((ref) {
  return RouteRemoteDataSource();
});

// Geocoding Remote Data Source Provider (Mapbox Geocoding API)
final geocodingRemoteDataSourceProvider = Provider<GeocodingRemoteDataSource>((
  ref,
) {
  return GeocodingRemoteDataSource();
});

// Map Repository Provider
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final dataSource = ref.watch(mapDataSourceProvider);
  final routeRemoteDataSource = ref.watch(routeRemoteDataSourceProvider);
  return MapRepositoryImpl(
    remoteDataSource: dataSource,
    routeRemoteDataSource: routeRemoteDataSource,
  );
});

// Stop Data Source Provider
final stopLocalDataSourceProvider = Provider<StopLocalDataSource>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return StopLocalDataSource(databaseService);
});

// Stop Repository Provider
final stopRepositoryProvider = Provider<StopRepository>((ref) {
  final localDataSource = ref.watch(stopLocalDataSourceProvider);
  return StopRepositoryImpl(localDataSource: localDataSource);
});

// Geocoding Repository Provider
final geocodingRepositoryProvider = Provider<GeocodingRepository>((ref) {
  final remoteDataSource = ref.watch(geocodingRemoteDataSourceProvider);
  return GeocodingRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Stop Use Cases Providers
final getStopsByRouteProvider = Provider<GetStopsByRoute>((ref) {
  final repository = ref.watch(stopRepositoryProvider);
  return GetStopsByRoute(repository);
});

final createStopProvider = Provider<CreateStop>((ref) {
  final repository = ref.watch(stopRepositoryProvider);
  return CreateStop(repository);
});

final updateStopProvider = Provider<UpdateStop>((ref) {
  final repository = ref.watch(stopRepositoryProvider);
  return UpdateStop(repository);
});

final deleteStopProvider = Provider<DeleteStop>((ref) {
  final repository = ref.watch(stopRepositoryProvider);
  return DeleteStop(repository);
});

final reorderStopsProvider = Provider<ReorderStops>((ref) {
  final repository = ref.watch(stopRepositoryProvider);
  return ReorderStops(repository);
});

final createStopFromCoordinatesProvider = Provider<CreateStopFromCoordinates>((
  ref,
) {
  final repository = ref.watch(stopRepositoryProvider);
  return CreateStopFromCoordinates(repository);
});

// Geocoding Use Cases Providers
final reverseGeocodeCoordinatesProvider = Provider<ReverseGeocodeCoordinates>((
  ref,
) {
  final repository = ref.watch(geocodingRepositoryProvider);
  return ReverseGeocodeCoordinates(repository);
});
