import 'package:fpdart/fpdart.dart';
import 'package:vector/core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String account,
    required String password,
  });
  
  Future<void> logout();
  
  Future<Option<User>> getCurrentUser();
}
