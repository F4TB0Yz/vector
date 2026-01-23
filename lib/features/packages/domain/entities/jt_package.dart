import 'package:vector/features/packages/domain/entities/package_entity.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; // Import for Position
import 'package:vector/features/packages/domain/entities/package_status.dart'; // Import for PackageStatus

class JTPackage extends PackageEntity {
  final String waybillNo;
  final String waybillId;
  final int taskStatus; // Original integer from J&T API
  final bool isAbnormal;
  final String scanTime;
  final String? signTime;
  final String deliverStaff;
  final double distance;
  // lngLat is often null or "0.0,0.0" in string format based on usage
  final String? lngLat;
  final bool isGrouped; // Indica si el paquete pertenece a un grupo

  const JTPackage({
    required this.waybillNo,
    required this.waybillId,
    required super.receiverName,
    required super.phone,
    required super.address,
    required super.status,
    super.notes,
    required this.taskStatus,
    required this.isAbnormal,
    required this.scanTime,
    this.signTime,
    required this.deliverStaff,
    required this.distance,
    this.lngLat,
    this.isGrouped = false,
    super.coordinates,
  }) : super(id: waybillNo);

  @override
  JTPackage copyWith({
    String? id, // Note: id is derived from waybillNo
    String? receiverName,
    String? address,
    String? phone,
    String? notes,
    Position? coordinates,
    PackageStatus? status,
    DateTime? updatedAt,
    String? waybillNo,
    String? waybillId,
    int? taskStatus,
    bool? isAbnormal,
    String? scanTime,
    String? signTime,
    String? deliverStaff,
    double? distance,
    String? lngLat,
    bool? isGrouped,
  }) {
    return JTPackage(
      waybillNo: waybillNo ?? this.waybillNo,
      waybillId: waybillId ?? this.waybillId,
      receiverName: receiverName ?? this.receiverName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      taskStatus: taskStatus ?? this.taskStatus,
      isAbnormal: isAbnormal ?? this.isAbnormal,
      scanTime: scanTime ?? this.scanTime,
      signTime: signTime ?? this.signTime,
      deliverStaff: deliverStaff ?? this.deliverStaff,
      distance: distance ?? this.distance,
      lngLat: lngLat ?? this.lngLat,
      isGrouped: isGrouped ?? this.isGrouped,
      coordinates: coordinates ?? this.coordinates,
      // updatedAt is not a constructor parameter in JTPackage, but in PackageEntity.
      // If we need to update updatedAt, we would have to reconstruct the superclass
      // explicitly, or add it as a parameter to JTPackage constructor if it's meant to be mutable there.
      // For now, it's ignored as it's not directly in JTPackage's constructor.
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    waybillNo,
    waybillId,
    taskStatus,
    isAbnormal,
    scanTime,
    signTime,
    deliverStaff,
    distance,
    lngLat,
    isGrouped,
  ];
}
