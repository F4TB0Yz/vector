import '../repositories/auth_repository.dart';

class GetSavedCredentials {
  final AuthRepository _repository;

  GetSavedCredentials(this._repository);

  Future<Map<String, String>?> call() {
    return _repository.getSavedCredentials();
  }
}
