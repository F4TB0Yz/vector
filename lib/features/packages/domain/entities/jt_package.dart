import 'package:vector/features/packages/domain/entities/package_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';

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
    super.coordinates,
  }) : super(
          id: waybillNo,
        );

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
      ];
}
