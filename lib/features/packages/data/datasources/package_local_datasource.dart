import 'package:vector/features/packages/domain/entities/package_status.dart';

abstract class PackageLocalDataSource {
  Future<void> updatePackageStatus(String packageId, PackageStatus status);
}
