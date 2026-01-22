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

  RouteEntity copyWith({
    String? id,
    String? name,
    DateTime? date,
    double? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<StopEntity>? stops,
  }) {
    return RouteEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stops: stops ?? this.stops,
    );
  }

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

