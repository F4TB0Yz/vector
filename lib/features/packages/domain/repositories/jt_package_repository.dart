import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/jt_package.dart';

abstract class JTPackageRepository {
  Future<Either<Failure, List<JTPackage>>> getJTPackages();
}
