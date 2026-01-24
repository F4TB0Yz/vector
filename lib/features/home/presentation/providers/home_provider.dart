import 'package:flutter/foundation.dart';
import 'package:vector/features/routes/domain/usecases/add_stop_to_route.dart';
import 'package:vector/features/map/domain/entities/stop_entity.dart';

class HomeProvider extends ChangeNotifier {
  final AddStopToRoute _addStopToRouteUseCase;

  HomeProvider({
    required AddStopToRoute addStopToRouteUseCase,
  }) : _addStopToRouteUseCase = addStopToRouteUseCase;

  Future<void> savePackageToRoute({
    required String routeId,
    required StopEntity stop,
  }) async {
    final result = await _addStopToRouteUseCase(
      AddStopParams(routeId: routeId, stop: stop),
    );

    result.fold(
      (failure) => throw Exception(failure.message),
      (_) => null,
    );
  }
}
