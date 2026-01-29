import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/exceptions.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/packages/data/datasources/package_local_datasource.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';
import 'package:vector/features/packages/domain/repositories/package_repository.dart';

class PackageRepositoryImpl implements PackageRepository {
  final PackageLocalDataSource localDataSource;

  PackageRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, void>> updatePackageStatus(
      String packageId, PackageStatus status) async {
    try {
      await localDataSource.updatePackageStatus(packageId, status);
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure('Failed to update package status'));
    }
  }
}
