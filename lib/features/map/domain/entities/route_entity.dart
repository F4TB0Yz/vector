import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

class RouteEntity extends Equatable {
  final String id;
  final String name;
  final List<Position> polyline;
  final List<StopEntity> stops;
  final double progress; // 0.0 to 1.0

  const RouteEntity({
    required this.id,
    required this.name,
    required this.polyline,
    required this.stops,
    this.progress = 0.0,
  });

  RouteEntity copyWith({
    String? id,
    String? name,
    List<Position>? polyline,
    List<StopEntity>? stops,
    double? progress,
  }) {
    return RouteEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      polyline: polyline ?? this.polyline,
      stops: stops ?? this.stops,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [id, name, polyline, stops, progress];
}
