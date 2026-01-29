import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';

abstract class PackageRepository {
  Future<Either<Failure, void>> updatePackageStatus(String packageId, PackageStatus status);
}
