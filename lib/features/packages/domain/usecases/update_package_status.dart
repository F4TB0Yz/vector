import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/packages/domain/repositories/package_repository.dart';

class UpdatePackageStatus {
  final PackageRepository repository;

  UpdatePackageStatus(this.repository);

  Future<Either<Failure, void>> call(UpdatePackageStatusParams params) async {
    return await repository.updatePackageStatus(params.packageId, params.status);
  }
}

class UpdatePackageStatusParams {
  final String packageId;
  final PackageStatus status;

  UpdatePackageStatusParams({required this.packageId, required this.status});
}
