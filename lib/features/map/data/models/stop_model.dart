import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

/// Modelo de datos para StopEntity con serialización SQLite.
class StopModel {
  final String id;
  final String routeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String status;
  final int stopOrder;
  final int createdAt;
  final int updatedAt;

  StopModel({
    required this.id,
    required this.routeId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.stopOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convierte desde Map (SQLite) a StopModel.
  factory StopModel.fromMap(Map<String, dynamic> map) {
    return StopModel(
      id: map['id'] as String,
      routeId: map['route_id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      status: map['status'] as String,
      stopOrder: map['stop_order'] as int,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convierte a Map para SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'stop_order': stopOrder,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Convierte a StopEntity.
  StopEntity toEntity() {
    return StopEntity(
      id: id,
      name: name,
      address: address,
      coordinates: Position(longitude, latitude),
      status: _parseStatus(status),
      stopOrder: stopOrder,
    );
  }

  /// Convierte desde StopEntity.
  factory StopModel.fromEntity(StopEntity entity, String routeId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return StopModel(
      id: entity.id,
      routeId: routeId,
      name: entity.name,
      address: entity.address,
      latitude: entity.coordinates.lat.toDouble(),
      longitude: entity.coordinates.lng.toDouble(),
      status: _statusToString(entity.status),
      stopOrder: entity.stopOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Parsea el status desde String a enum.
  static StopStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return StopStatus.pending;
      case 'completed':
        return StopStatus.completed;
      case 'failed':
        return StopStatus.failed;
      default:
        return StopStatus.pending;
    }
  }

  /// Convierte el status de enum a String.
  static String _statusToString(StopStatus status) {
    switch (status) {
      case StopStatus.pending:
        return 'pending';
      case StopStatus.completed:
        return 'completed';
      case StopStatus.failed:
        return 'failed';
    }
  }
}
