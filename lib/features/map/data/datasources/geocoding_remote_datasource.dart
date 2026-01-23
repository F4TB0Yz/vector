import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/map/data/models/address_model.dart';

/// Remote data source for Mapbox Geocoding API.
class GeocodingRemoteDataSource {
  final Dio _dio;

  GeocodingRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio();

  /// Reverse geocode: Convert coordinates to address using Mapbox API.
  ///
  /// API: GET https://api.mapbox.com/geocoding/v5/mapbox.places/{lng},{lat}.json
  ///
  /// Throws [DioException] on network errors.
  /// Throws [FormatException] on invalid response format.
  Future<AddressModel> reverseGeocode(Position coordinates) async {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];

    if (token == null || token.isEmpty) {
      throw Exception('MAPBOX_ACCESS_TOKEN not found in environment');
    }

    final lng = coordinates.lng.toStringAsFixed(6);
    final lat = coordinates.lat.toStringAsFixed(6);
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json';

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'access_token': token,
          'types': 'address,poi', // Address or Point of Interest
          'limit': 1, // Only the closest result
          'language': 'es', // Spanish
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode == 200) {
        return AddressModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: 'Geocoding API returned status ${response.statusCode}',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw Exception('Unexpected error in geocoding: $e');
    }
  }
}
