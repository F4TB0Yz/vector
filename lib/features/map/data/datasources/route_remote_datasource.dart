import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Remote data source for fetching route geometry from Mapbox Directions API
class RouteRemoteDataSource {
  final Dio _dio;

  RouteRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio();

  /// Fetches detailed route polyline that follows roads using Mapbox Directions API
  ///
  /// Takes a list of [stops] (waypoints) and returns a detailed polyline with
  /// thousands of points that follow actual roads.
  ///
  /// Falls back to original stops if:
  /// - Network error occurs
  /// - API returns error
  /// - Response is invalid
  ///
  /// Mapbox Directions API limits:
  /// - Maximum 25 waypoints per request
  /// - 600 requests/minute (free tier)
  Future<List<Position>> getRoutePolyline(List<Position> stops) async {
    // Need at least 2 points to create a route
    if (stops.length < 2) return stops;

    // Check for API token
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token == null || token.isEmpty) {
      _logInfo('⚠️ No Mapbox token found, using fallback route');
      return stops; // Fallback if no token
    }

    _logInfo('🗺️ Fetching route from Mapbox API for ${stops.length} stops...');

    // Mapbox API limit: max 25 waypoints
    if (stops.length > 25) {
      _logInfo('⚠️ Route has ${stops.length} stops, using only first 25');
      // TODO: Implement chunking for routes with >25 stops
      // For now, use only first 25 stops
      return _fetchRoute(stops.take(25).toList(), token);
    }

    return _fetchRoute(stops, token);
  }

  Future<List<Position>> _fetchRoute(List<Position> stops, String token) async {
    // Format coordinates as: lng,lat;lng,lat;...
    final coordinatesString = stops
        .map((position) => '${position.lng},${position.lat}')
        .join(';');

    final url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/$coordinatesString';

    _logInfo('📡 Calling: $url');

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'geometries': 'geojson', // GeoJSON format for geometry
          'overview': 'full', // Full geometry (not simplified)
          'access_token': token,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );

      // Check if response is successful and has routes
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final routes = data['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'] as Map<String, dynamic>?;

          if (geometry != null) {
            final coordinates = geometry['coordinates'] as List?;

            if (coordinates != null && coordinates.isNotEmpty) {
              // Convert coordinates to Position objects
              final polyline = coordinates.map((coord) {
                final lng = (coord[0] as num).toDouble();
                final lat = (coord[1] as num).toDouble();
                return Position(lng, lat);
              }).toList();

              _logInfo('✅ Received ${polyline.length} points from Mapbox API');
              return polyline;
            }
          }
        }
      }

      // If we reach here, response was not as expected
      _logInfo('⚠️ Invalid response from Mapbox API, using fallback');
      return stops; // Fallback
    } on DioException catch (e) {
      // Network error, timeout, or API error
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        // Expected errors when offline - log as info
        _logInfo('ℹ️ No internet connection, using fallback route');
      } else if (e.type == DioExceptionType.badResponse) {
        _logError('API returned error (${e.response?.statusCode})', e.message);
      } else {
        // Unexpected API errors
        _logError('Mapbox Directions API error (${e.type.name})', e.message);
      }
      return stops; // Fallback
    } catch (e) {
      // Unexpected error (parsing, etc.)
      _logError('Unexpected error fetching route', e);
      return stops; // Fallback
    }
  }

  void _logInfo(String message) {
    // ignore: avoid_print
    print('[RouteRemoteDataSource] $message');
  }

  void _logError(String message, dynamic error) {
    // In production, use proper logging service
    // ignore: avoid_print
    print('[RouteRemoteDataSource] ❌ $message: $error');
  }
}
