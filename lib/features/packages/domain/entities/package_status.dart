enum PackageStatus {
  pending,
  inTransit,
  outForDelivery,
  delivered,
  failed,
  returned,
}

extension PackageStatusX on PackageStatus {
  String toLocalizedString() {
    switch (this) {
      case PackageStatus.pending:
        return 'Pendiente';
      case PackageStatus.inTransit:
        return 'En Tránsito';
      case PackageStatus.outForDelivery:
        return 'En Reparto';
      case PackageStatus.delivered:
        return 'Entregado';
      case PackageStatus.failed:
        return 'Fallido';
      case PackageStatus.returned:
        return 'Devuelto';
    }
  }
}
