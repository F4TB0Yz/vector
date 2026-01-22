import '../../domain/entities/jt_package.dart';

class JTPackageModel extends JTPackage {
  const JTPackageModel({
    required super.waybillNo,
    required super.waybillId,
    required super.receiverName,
    required super.phone,
    required super.address,
    required super.city,
    required super.area,
    required super.taskStatus,
    required super.isAbnormal,
    required super.scanTime,
    super.signTime,
    required super.deliverStaff,
    required super.distance,
    super.lngLat,
  });

  factory JTPackageModel.fromJson(Map<String, dynamic> json) {
    return JTPackageModel(
      waybillNo: json['waybillNo'] ?? '',
      waybillId: json['waybillId'] ?? '',
      receiverName: json['receiverName'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      area: json['area'] ?? '',
      taskStatus: json['taskStatus'] ?? 0,
      // Handle int (1/0) or boolean for isAbnormal
      isAbnormal: (json['isAbnormal'] is int)
          ? json['isAbnormal'] == 1
          : (json['isAbnormal'] ?? false),
      scanTime: json['scanTime'] ?? '',
      signTime: json['signTime'],
      deliverStaff: json['deliverStaff'] ?? '',
      // Handles both int and double for distance
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      lngLat: json['lngLat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'waybillNo': waybillNo,
      'waybillId': waybillId,
      'receiverName': receiverName,
      'phone': phone,
      'address': address,
      'city': city,
      'area': area,
      'taskStatus': taskStatus,
      'isAbnormal': isAbnormal,
      'scanTime': scanTime,
      'signTime': signTime,
      'deliverStaff': deliverStaff,
      'distance': distance,
      'lngLat': lngLat,
    };
  }
}
