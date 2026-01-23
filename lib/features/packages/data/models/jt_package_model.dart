import '../../domain/entities/jt_package.dart';
import '../../domain/entities/package_status.dart';

class JTPackageModel extends JTPackage {
  const JTPackageModel({
    required super.waybillNo,
    required super.waybillId,
    required super.receiverName,
    required super.phone,
    required super.address,
    required super.status,
    super.notes,
    required super.taskStatus,
    required super.isAbnormal,
    required super.scanTime,
    super.signTime,
    required super.deliverStaff,
    required super.distance,
    super.lngLat,
    super.coordinates,
  });

  factory JTPackageModel.fromJson(Map<String, dynamic> json) {
    final tStatus = json['taskStatus'] ?? 0;
    
    // Map J&T taskStatus to our unified PackageStatus
    // Assuming: 1=pending, 2=inTransit, 3=outForDelivery, 4=delivered, 5=failed
    PackageStatus unifiedStatus;
    switch (tStatus) {
      case 1:
        unifiedStatus = PackageStatus.pending;
        break;
      case 2:
        unifiedStatus = PackageStatus.inTransit;
        break;
      case 3:
        unifiedStatus = PackageStatus.outForDelivery;
        break;
      case 4:
        unifiedStatus = PackageStatus.delivered;
        break;
      case 5:
        unifiedStatus = PackageStatus.failed;
        break;
      default:
        unifiedStatus = PackageStatus.pending;
    }

    return JTPackageModel(
      waybillNo: json['waybillNo'] ?? '',
      waybillId: json['waybillId'] ?? '',
      receiverName: json['receiverName'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      status: unifiedStatus,
      taskStatus: tStatus,
      isAbnormal: (json['isAbnormal'] is int)
          ? json['isAbnormal'] == 1
          : (json['isAbnormal'] ?? false),
      scanTime: json['scanTime'] ?? '',
      signTime: json['signTime'],
      deliverStaff: json['deliverStaff'] ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      lngLat: json['lngLat'],
      notes: json['remark'] ?? json['notes'], // J&T uses 'remark' for notes often
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'waybillNo': waybillNo,
      'waybillId': waybillId,
      'receiverName': receiverName,
      'phone': phone,
      'address': address,
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
