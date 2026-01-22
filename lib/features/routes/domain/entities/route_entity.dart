import 'package:equatable/equatable.dart';

class RouteEntity extends Equatable {
  final String id;
  final String name;
  final DateTime date;
  final double progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RouteEntity({
    required this.id,
    required this.name,
    required this.date,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, date, progress, createdAt, updatedAt];
}
