import 'package:flutter/cupertino.dart';
import '../../../../domain/repositories/auth_repository.dart';

/// ViewModel that manages sign-in logic and state for the UI.
/// Delegates authentication to the AuthRepository.
class SignInViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool isLoading = false;
  String errorMessage = '';

  SignInViewModel(this._authRepository);

  /// Tries to sign in with email and password.
  /// Shows loading and error state to the UI.
  Future<void> signIn(String email, String password) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    final error = await _authRepository.signInWithEmailAndPassword(email, password);

    if (error != null) {
      errorMessage = error;
    }

    isLoading = false;
    notifyListeners();
  }
}
