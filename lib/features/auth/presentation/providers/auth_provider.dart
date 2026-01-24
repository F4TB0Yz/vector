import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/save_credentials.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final LoginUseCase _loginUseCase;
  final SaveCredentials _saveCredentialsUseCase;

  Option<User> _user = const Option.none();
  bool _isLoading = false;
  String? _error;

  // Getters
  Option<User> get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user.isSome();

  AuthProvider({
    required AuthRepository authRepository,
    required LoginUseCase loginUseCase,
    required SaveCredentials saveCredentialsUseCase,
  })  : _authRepository = authRepository,
        _loginUseCase = loginUseCase,
        _saveCredentialsUseCase = saveCredentialsUseCase;

  /// Check current auth status (e.g. on app start)
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.getCurrentUser();
      _user = result;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(
    String account,
    String password, {
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _loginUseCase(account: account, password: password);

    result.fold(
      (Failure failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (User user) {
        _user = Some(user);
        
        // Handle Remember Me
        if (rememberMe) {
          _saveCredentialsUseCase(account, password);
        } else {
          _saveCredentialsUseCase.clear();
        }

        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authRepository.logout();
    _user = const Option.none();
    
    _isLoading = false;
    notifyListeners();
  }
}
