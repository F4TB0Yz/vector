
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vector/features/packages/data/datasources/jt_packages_datasource.dart';
import 'package:vector/features/packages/data/repositories/jt_package_repository_impl.dart';
import 'package:vector/features/packages/domain/repositories/jt_package_repository.dart';
import 'package:vector/features/packages/domain/entities/jt_package.dart';
import 'package:vector/features/auth/presentation/providers/auth_provider.dart';


// --- Dependencies ---

final jtPackagesDataSourceProvider = Provider<JTPackagesDataSource>((ref) {
  // We can reuse the same Dio instance from Auth, or create a new one.
  // Reusing is better for connection pooling if configured.
  return JTPackagesDataSourceImpl(ref.watch(dioProvider));
});

final jtPackageRepositoryProvider = Provider<JTPackageRepository>((ref) {
  return JTPackageRepositoryImpl(
    ref.watch(jtPackagesDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  );
});

// --- State ---

final jtPackagesProvider = AsyncNotifierProvider<JTPackagesNotifier, List<JTPackage>>(JTPackagesNotifier.new);

class JTPackagesNotifier extends AsyncNotifier<List<JTPackage>> {
  @override
  FutureOr<List<JTPackage>> build() {
    return [];
  }

  Future<void> importPackages() async {
    state = const AsyncValue.loading();
    final repository = ref.read(jtPackageRepositoryProvider);
    final result = await repository.getJTPackages();

    result.fold(
      (failure) {
        if (failure.message.contains('Sesión expirada') || failure.message.contains('135010037')) {
          ref.read(authProvider.notifier).logout();
        }
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (packages) {
        state = AsyncValue.data(packages);
      },
    );
  }
}
