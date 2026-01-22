import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import 'package:vector/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:vector/features/packages/data/datasources/jt_packages_datasource.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/packages/domain/repositories/jt_package_repository.dart';

class JTPackageRepositoryImpl implements JTPackageRepository {
  final JTPackagesDataSource dataSource;
  final AuthLocalDataSource authLocalDataSource;

  JTPackageRepositoryImpl(this.dataSource, this.authLocalDataSource);

  @override
  Future<Either<Failure, List<JTPackage>>> getJTPackages() async {
    try {
      final token = await authLocalDataSource.getToken();

      if (token == null || token.isEmpty) {
        return const Left(
          ValidationFailure('No Authentication Token Found. Please Login.'),
        );
      }

      final packages = await dataSource.getPackages(token);
      return Right(packages);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
