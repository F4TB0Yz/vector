import 'package:equatable/equatable.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

enum StopStatus { pending, completed, failed }

class StopEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final Position coordinates;
  final StopStatus status;
  final int stopOrder;

  const StopEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.coordinates,
    this.status = StopStatus.pending,
    required this.stopOrder,
  });

  StopEntity copyWith({
    String? id,
    String? name,
    String? address,
    Position? coordinates,
    StopStatus? status,
    int? stopOrder,
  }) {
    return StopEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      status: status ?? this.status,
      stopOrder: stopOrder ?? this.stopOrder,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    coordinates,
    status,
    stopOrder,
  ];
}
