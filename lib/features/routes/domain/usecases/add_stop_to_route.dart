import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';
import 'package:vector/features/routes/domain/repositories/routes_repository.dart';

class AddStopToRoute {
  final RoutesRepository repository;

  AddStopToRoute(this.repository);

  Future<Either<Failure, void>> call(AddStopParams params) async {
    return await repository.addStop(params.routeId, params.stop);
  }
}

class AddStopParams extends Equatable {
  final String routeId;
  final StopEntity stop;

  const AddStopParams({required this.routeId, required this.stop});

  @override
  List<Object?> get props => [routeId, stop];
}
