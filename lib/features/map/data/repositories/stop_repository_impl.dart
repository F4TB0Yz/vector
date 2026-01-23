import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/exceptions.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/data/datasources/stop_local_datasource.dart';
import 'package:vector/features/map/data/models/stop_model.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/map/domain/repositories/stop_repository.dart';

/// Implementación del repositorio de paradas usando SQLite.
class StopRepositoryImpl implements StopRepository {
  final StopLocalDataSource localDataSource;

  StopRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<StopEntity>>> getStopsByRoute(
    String routeId,
  ) async {
    try {
      final stopModels = await localDataSource.getStopsByRoute(routeId);
      final stops = stopModels.map((model) => model.toEntity()).toList();
      return Right(stops);
    } on VectorDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, StopEntity>> createStop(StopEntity stop) async {
    try {
      // FIX: Use the routeId from the StopEntity instead of a hardcoded value.
      final stopModel = StopModel.fromEntity(stop, stop.routeId);
      final createdModel = await localDataSource.createStop(stopModel);
      return Right(createdModel.toEntity());
    } on VectorDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, StopEntity>> updateStop(StopEntity stop) async {
    try {
      final stopModel = StopModel.fromEntity(stop, stop.routeId);
      final updatedModel = await localDataSource.updateStop(stopModel);
      return Right(updatedModel.toEntity());
    } on VectorDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStop(String stopId) async {
    try {
      await localDataSource.deleteStop(stopId);
      return const Right(null);
    } on VectorDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> reorderStops(
    String routeId,
    List<String> stopIds,
  ) async {
    try {
      await localDataSource.reorderStops(routeId, stopIds);
      return const Right(null);
    } on VectorDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: $e'));
    }
  }
}
