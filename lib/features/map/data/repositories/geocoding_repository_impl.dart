import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/data/datasources/geocoding_remote_datasource.dart';
import 'package:vector/features/map/domain/entities/address_entity.dart';
import 'package:vector/features/map/domain/repositories/geocoding_repository.dart';

/// Implementation of [GeocodingRepository] using remote data source.
class GeocodingRepositoryImpl implements GeocodingRepository {
  final GeocodingRemoteDataSource remoteDataSource;

  GeocodingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AddressEntity>> reverseGeocode(
    Position coordinates,
  ) async {
    try {
      final model = await remoteDataSource.reverseGeocode(coordinates);
      return Right(model.toEntity());
    } on DioException catch (e) {
      // Network errors, timeouts, etc.
      return Left(ServerFailure(_handleDioError(e)));
    } on FormatException catch (e) {
      // Invalid JSON or no features found
      return Left(
        ServerFailure(
          'Error al procesar la respuesta del servidor: ${e.message}',
        ),
      );
    } catch (e) {
      // Unexpected errors
      return Left(ServerFailure('Error inesperado al geocodificar: $e'));
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado. Verifica tu conexión a internet.';
      case DioExceptionType.connectionError:
        return 'No se pudo conectar al servidor. Verifica tu conexión.';
      case DioExceptionType.badResponse:
        return 'Error del servidor (${e.response?.statusCode ?? 'unknown'})';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada';
      default:
        return 'Error de red: ${e.message ?? 'Desconocido'}';
    }
  }
}
