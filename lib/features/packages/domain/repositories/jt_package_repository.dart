import 'package:fpdart/fpdart.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../core/error/failures.dart';
import '../entities/jt_package.dart';

abstract class JTPackageRepository {
  Future<Either<Failure, List<JTPackage>>> getJTPackages();
  
  Future<Either<Failure, void>> updatePackageCoordinates(
    String waybillNo,
    Position coordinates,
  );
}
