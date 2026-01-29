import 'package:vector/core/database/database_service.dart';
import 'package:vector/core/error/exceptions.dart';
import 'package:vector/features/packages/data/datasources/package_local_datasource.dart';
import 'package:vector/features/packages/domain/entities/package_status.dart';

class PackageLocalDataSourceImpl implements PackageLocalDataSource {
  final DatabaseService databaseService;

  PackageLocalDataSourceImpl({required this.databaseService});

  @override
  Future<void> updatePackageStatus(String packageId, PackageStatus status) async {
    try {
      final db = await databaseService.database;
      // In our current DB schema (see database_service.dart), we store package info
      // inside the 'stops' table. We do NOT have a separate 'packages' table.
      // So we must update the 'stops' table.
      // Also, the 'status' column in 'stops' table is defined as TEXT in _onCreate.
      // But here we are trying to save it as int (status.index).
      // We should be consistent.
      // Reading _onCreate in DatabaseService: status TEXT NOT NULL
      // So we should save status.name or status.toString().
      // Let's check how we read it. StopModel._parseStatus reads strings.
      // So we should save status.name.

      await db.update(
        'stops', // Table is 'stops', not 'packages'
        {'status': status.name}, // Column is TEXT, so use .name
        where: 'id = ?',
        whereArgs: [packageId], // The stop ID is the same as package ID in our current logic
      );
    } catch (e) {
      throw CacheException('Failed to update package status: $e');
    }
  }
}
