import '../../domain/entities/route_entity.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

class RouteModel extends RouteEntity {
  const RouteModel({
    required super.id,
    required super.name,
    required super.date,
    required super.progress,
    required super.createdAt,
    required super.updatedAt,
    super.stops,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      name: json['name'],
      date: DateTime.fromMillisecondsSinceEpoch(json['date']),
      progress: (json['progress'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at']),
      stops: const [],
    );
  }

  factory RouteModel.fromMap(
    Map<String, dynamic> map, {
    List<StopEntity> stops = const [],
  }) {
    return RouteModel(
      id: map['id'],
      name: map['name'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      progress: (map['progress'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      stops: stops,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.millisecondsSinceEpoch,
      'progress': progress,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }
}
