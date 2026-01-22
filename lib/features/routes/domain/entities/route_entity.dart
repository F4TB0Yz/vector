import 'package:equatable/equatable.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

class RouteEntity extends Equatable {
  final String id;
  final String name;
  final DateTime date;
  final double progress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StopEntity> stops;

  const RouteEntity({
    required this.id,
    required this.name,
    required this.date,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.stops = const [],
  });

  @override
  List<Object?> get props => [
    id,
    name,
    date,
    progress,
    createdAt,
    updatedAt,
    stops,
  ];
}
