import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/jt_auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final JtAuthService _authService;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl(this._authService, this._localDataSource);

  @override
  Future<Either<Failure, User>> login({
    required String account,
    required String password,
  }) async {
    try {
      final user = await _authService.login(account, password);

      // Save user and token locally
      await _localDataSource.saveUser(user);

      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearAuth();
  }

  @override
  Future<Option<User>> getCurrentUser() async {
    final user = await _localDataSource.getUser();
    return user != null ? Some(user) : const Option.none();
  }

  @override
  Future<void> saveCredentials(String account, String password) async {
    await _localDataSource.saveCredentials(account, password);
  }

  @override
  Future<Map<String, String>?> getSavedCredentials() async {
    return await _localDataSource.getCredentials();
  }

  @override
  Future<void> clearSavedCredentials() async {
    await _localDataSource.clearCredentials();
  }
}
