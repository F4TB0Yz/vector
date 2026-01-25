import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class OptimizationRemoteDataSource {
  final Dio _dio;

  OptimizationRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio();

  Future<List<int>> getOptimizedOrder({
    required List<Position> waypoints,
    required Position start,
    required Position end,
  }) async {
    final baseUrl = dotenv.env['PYTHON_API_URL'] ?? 'http://localhost:8000';
    final url = '$baseUrl/api/route-optimizer/optimize';

    final List<Map<String, dynamic>> locations = [];
    for (int i = 0; i < waypoints.length; i++) {
      locations.add({
        'id': i,
        'lat': waypoints[i].lat.toDouble(),
        'lon': waypoints[i].lng.toDouble(),
        'nombre': 'Punto $i',
      });
    }

    final data = {
      'locations': locations,
      'start': {'lat': start.lat.toDouble(), 'lon': start.lng.toDouble()},
      'end': {'lat': end.lat.toDouble(), 'lon': end.lng.toDouble()},
      'config': {
        'criterio': 'distancia',
        'vehiculo': 'carro',
        'tiempo_limite_segundos': 10,
      },
    };

    try {
      _logInfo('🚀 Sending optimization request to: $url');
      _logInfo(
        '📊 Waypoints: ${waypoints.length}, returnToStart: ${start == end}',
      );

      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> optimizedIndices = response.data['route'];
        _logInfo('✅ Optimization successful. New order: $optimizedIndices');
        return optimizedIndices.cast<int>();
      } else {
        _logError(
          '❌ Failed to optimize route: ${response.statusCode} - ${response.data}',
        );
        throw Exception('Failed to optimize route: ${response.statusCode}');
      }
    } catch (e) {
      _logError('❌ Error calling optimization API: $e');
      throw Exception('Error calling optimization API: $e');
    }
  }

  void _logInfo(String message) {
    // ignore: avoid_print
    print('\x1B[34m[OptimizationAPI] $message\x1B[0m');
  }

  void _logError(String message) {
    // ignore: avoid_print
    print('\x1B[31m[OptimizationAPI] $message\x1B[0m');
  }
}
