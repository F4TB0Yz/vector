import '../repositories/auth_repository.dart';

class SaveCredentials {
  final AuthRepository _repository;

  SaveCredentials(this._repository);

  Future<void> call(String account, String password) {
    return _repository.saveCredentials(account, password);
  }

  Future<void> clear() {
    return _repository.clearSavedCredentials();
  }
}
