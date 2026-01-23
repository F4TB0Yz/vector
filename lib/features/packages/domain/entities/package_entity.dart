import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';

abstract class PackageEntity extends Equatable {
  final String id; // Tracking Number o ID interno
  final String receiverName;
  final String address;
  final String phone;
  final String? notes;
  final Position? coordinates;
  final PackageStatus status;
  final DateTime? updatedAt;

  const PackageEntity({
    required this.id,
    required this.receiverName,
    required this.address,
    required this.phone,
    this.notes,
    this.coordinates,
    this.status = PackageStatus.pending,
    this.updatedAt,
  });

  PackageEntity copyWith({
    String? id,
    String? receiverName,
    String? address,
    String? phone,
    String? notes,
    Position? coordinates,
    PackageStatus? status,
    DateTime? updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        receiverName,
        address,
        phone,
        coordinates,
        status,
        updatedAt,
      ];
}
