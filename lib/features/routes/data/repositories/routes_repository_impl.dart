import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/routes_repository.dart';
import '../datasources/routes_local_datasource.dart';

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
}
