import 'package:vector/features/map/domain/entities/stop_entity.dart';

extension StopStatusExtension on StopStatus {
  String toLocalizedString() {
    switch (this) {
      case StopStatus.pending:
        return 'PENDIENTE';
      case StopStatus.completed:
        return 'ENTREGADO';
      case StopStatus.failed:
        return 'FALLIDO';
    }
  }
}
