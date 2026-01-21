import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Either<Failure, User>> call({
    required String account,
    required String password,
  }) {
    return _repository.login(account: account, password: password);
  }
}
