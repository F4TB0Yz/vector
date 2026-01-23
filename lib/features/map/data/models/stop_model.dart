import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/packages/domain/entities/manual_package_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';

/// Modelo de datos para StopEntity con serialización SQLite.
class StopModel {
  final String id;
  final String routeId;
  final String name;
  final String address;
  final String phone;
  final String? notes;
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
    required this.phone,
    this.notes,
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
      phone: map['phone'] as String? ?? 'N/A',
      notes: map['notes'] as String?,
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
      'phone': phone,
      'notes': notes,
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
      package: ManualPackageEntity(
        id: id,
        receiverName: name,
        address: address,
        phone: phone,
        notes: notes,
        status: _parseStatus(status),
        coordinates: Position(longitude, latitude),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      ),
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
      phone: entity.package.phone,
      notes: entity.package.notes,
      latitude: entity.coordinates.lat.toDouble(),
      longitude: entity.coordinates.lng.toDouble(),
      status: _statusToString(entity.status),
      stopOrder: entity.stopOrder,
      createdAt: now,
      updatedAt: entity.package.updatedAt?.millisecondsSinceEpoch ?? now,
    );
  }

  /// Parsea el status desde String a enum.
  static PackageStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return PackageStatus.pending;
      case 'delivered':
      case 'completed':
        return PackageStatus.delivered;
      case 'failed':
        return PackageStatus.failed;
      default:
        return PackageStatus.pending;
    }
  }

  /// Convierte el status de enum a String.
  static String _statusToString(PackageStatus status) {
    switch (status) {
      case PackageStatus.pending:
        return 'pending';
      case PackageStatus.delivered:
        return 'delivered';
      case PackageStatus.failed:
        return 'failed';
      default:
        return 'pending';
    }
  }
}
