import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:vector/features/packages/domain/entities/package_entity.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';

class StopEntity extends Equatable {
  final String id;
  final String routeId;
  final PackageEntity package; // El paquete asociado a esta parada
  final int stopOrder;

  const StopEntity({
    required this.id,
    required this.routeId,
    required this.package,
    required this.stopOrder,
  });

  // Helper getters to maintain compatibility or ease of use
  String get name => package.receiverName;
  String get address => package.address;
  Position get coordinates => package.coordinates ?? Position(0, 0);
  PackageStatus get status => package.status;

  StopEntity copyWith({
    String? id,
    String? routeId,
    PackageEntity? package,
    int? stopOrder,
  }) {
    return StopEntity(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      package: package ?? this.package,
      stopOrder: stopOrder ?? this.stopOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        routeId,
        package,
        stopOrder,
      ];
}
