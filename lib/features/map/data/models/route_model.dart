import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/map/data/models/stop_model.dart';
import 'package:vector/features/map/domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

/// Modelo de datos para RouteEntity con serialización SQLite.
class RouteModel {
  final String id;
  final String name;
  final double progress;
  final int createdAt;
  final int updatedAt;
  final List<StopModel> stops;

  RouteModel({
    required this.id,
    required this.name,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.stops = const [],
  });

  /// Convierte desde Map (SQLite) a RouteModel.
  factory RouteModel.fromMap(
    Map<String, dynamic> map, {
    List<StopModel> stops = const [],
  }) {
    return RouteModel(
      id: map['id'] as String,
      name: map['name'] as String,
      progress: map['progress'] as double,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
      stops: stops,
    );
  }

  /// Convierte a Map para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'progress': progress,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Convierte a RouteEntity.
  RouteEntity toEntity() {
    // Generar polyline desde las paradas
    final polyline = stops.isNotEmpty
        ? stops.map((stop) => Position(stop.longitude, stop.latitude)).toList()
        : <Position>[];

    return RouteEntity(
      id: id,
      name: name,
      polyline: polyline,
      stops: stops.map((stop) => stop.toEntity()).toList(),
      progress: progress,
    );
  }

  /// Convierte desde RouteEntity.
  factory RouteModel.fromEntity(RouteEntity entity) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return RouteModel(
      id: entity.id,
      name: entity.name,
      progress: entity.progress,
      createdAt: now,
      updatedAt: now,
      stops: entity.stops
          .map((stop) => StopModel.fromEntity(stop, entity.id))
          .toList(),
    );
  }
}
