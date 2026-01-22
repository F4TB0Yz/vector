import 'package:equatable/equatable.dart';

class JTPackage extends Equatable {
  final String waybillNo;
  final String waybillId;
  final String receiverName;
  final String phone;
  final String address;
  final String city;
  final String area;
  final int taskStatus;
  final bool isAbnormal;
  final String scanTime;
  final String? signTime;
  final String deliverStaff;
  final double distance;
  // lngLat is often null or "0.0,0.0" in string format based on usage,
  // keeping it as String? for flexibility mapping from API
  final String? lngLat;

  const JTPackage({
    required this.waybillNo,
    required this.waybillId,
    required this.receiverName,
    required this.phone,
    required this.address,
    required this.city,
    required this.area,
    required this.taskStatus,
    required this.isAbnormal,
    required this.scanTime,
    this.signTime,
    required this.deliverStaff,
    required this.distance,
    this.lngLat,
  });

  @override
  List<Object?> get props => [
    waybillNo,
    waybillId,
    receiverName,
    phone,
    address,
    city,
    area,
    taskStatus,
    isAbnormal,
    scanTime,
    signTime,
    deliverStaff,
    distance,
    lngLat,
  ];
}
