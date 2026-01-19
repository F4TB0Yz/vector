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

  @override
  List<Object?> get props => [id, name, polyline, stops, progress];
}
