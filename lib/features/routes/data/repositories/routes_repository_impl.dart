import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/routes_repository.dart';
import '../datasources/routes_local_datasource.dart';
import 'package:vector/features/map/data/models/stop_model.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

class RoutesRepositoryImpl implements RoutesRepository {
  final RoutesLocalDataSource localDataSource;

  RoutesRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<RouteEntity>>> getRoutes() async {
    try {
      final result = await localDataSource.getRoutes();
      return Right(result);
    } on CacheException {
      return const Left(CacheFailure('Error al cargar rutas locales'));
    }
  }

  @override
  Future<Either<Failure, RouteEntity>> createRoute(String name, DateTime date) async {
    try {
      final result = await localDataSource.createRoute(name, date);
      return Right(result);
    } on CacheException {
      return const Left(CacheFailure('Error al crear la ruta'));
    }
  }

  @override
  Future<Either<Failure, void>> addStop(String routeId, StopEntity stop) async {
    try {
      final stopModel = StopModel.fromEntity(stop, routeId);
      await localDataSource.addStop(routeId, stopModel);
      return const Right(null);
    } on CacheException {
      return const Left(CacheFailure('Error al agregar parada'));
    }
  }
}
