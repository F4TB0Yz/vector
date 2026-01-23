import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/packages/domain/entities/package_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';

class ManualPackageEntity extends PackageEntity {
  const ManualPackageEntity({
    required super.id,
    required super.receiverName,
    required super.address,
    required super.phone,
    super.notes,
    super.coordinates,
    super.status = PackageStatus.pending,
    super.updatedAt,
  });

  @override
  ManualPackageEntity copyWith({
    String? id,
    String? receiverName,
    String? address,
    String? phone,
    Position? coordinates,
    PackageStatus? status,
    DateTime? updatedAt,
    String? notes,
  }) {
    return ManualPackageEntity(
      id: id ?? this.id,
      receiverName: receiverName ?? this.receiverName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      coordinates: coordinates ?? this.coordinates,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        notes,
      ];
}
