import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/jt_auth_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/save_credentials.dart';
import '../../domain/usecases/get_saved_credentials.dart';

// --- Dependencies ---

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final jtAuthServiceProvider = Provider<JtAuthService>((ref) {
  return JtAuthService(ref.watch(dioProvider));
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});

final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
  return AuthRepositoryImpl(
    ref.watch(jtAuthServiceProvider),
    ref.watch(authLocalDataSourceProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final saveCredentialsProvider = Provider<SaveCredentials>((ref) {
  return SaveCredentials(ref.watch(authRepositoryProvider));
});

final getSavedCredentialsProvider = Provider<GetSavedCredentials>((ref) {
  return GetSavedCredentials(ref.watch(authRepositoryProvider));
});

// --- State ---

class AuthNotifier extends AsyncNotifier<Option<User>> {
  @override
  Future<Option<User>> build() async {
    // Load cached user on initialization
    final repository = ref.watch(authRepositoryProvider);
    return await repository.getCurrentUser();
  }

  Future<void> login(
    String account,
    String password, {
    bool rememberMe = false,
  }) async {
    state = const AsyncLoading();

    final useCase = ref.read(loginUseCaseProvider);
    final saveCredentialsUseCase = ref.read(saveCredentialsProvider);

    final result = await useCase(account: account, password: password);

    state = result.fold(
      (Failure failure) => AsyncError(failure.message, StackTrace.current),
      (User user) {
        // Handle Remember Me
        if (rememberMe) {
          saveCredentialsUseCase(account, password);
        } else {
          saveCredentialsUseCase.clear();
        }
        return AsyncData(Some(user));
      },
    );
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = const AsyncData(Option.none());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, Option<User>>(
  () => AuthNotifier(),
);
