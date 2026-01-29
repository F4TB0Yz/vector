import 'package:flutter/foundation.dart';
import 'package:vector/core/database/database_service.dart';
import 'package:vector/core/database/migrations/fix_stop_order_migration.dart';

/// Provider para ejecutar la migración de stopOrder.
class MigrationProvider extends ChangeNotifier {
  final DatabaseService _databaseService;

  bool _isRunning = false;
  String? _error;
  int? _updatedCount;

  bool get isRunning => _isRunning;
  String? get error => _error;
  int? get updatedCount => _updatedCount;

  MigrationProvider(this._databaseService);

  /// Ejecuta la migración para reparar el orden de las paradas.
  Future<void> runStopOrderMigration() async {
    _isRunning = true;
    _error = null;
    _updatedCount = null;
    notifyListeners();

    try {
      final migration = FixStopOrderMigration(_databaseService);
      final count = await migration.execute();
      _updatedCount = count;
      _isRunning = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isRunning = false;
      notifyListeners();
    }
  }

  /// Limpia el estado de la migración.
  void clearState() {
    _error = null;
    _updatedCount = null;
    notifyListeners();
  }
}
