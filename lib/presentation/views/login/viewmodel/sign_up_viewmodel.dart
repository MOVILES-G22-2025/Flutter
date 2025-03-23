import 'package:flutter/cupertino.dart';
import '../../../../domain/repositories/auth_repository.dart';

/// ViewModel that manages user registration logic and state.
/// It uses AuthRepository to handle actual sign-up process.
class SignUpViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool isLoading = false;
  String errorMessage = '';

  SignUpViewModel(this._authRepository);

  /// Registers a new user with profile data.
  /// Shows loading and error feedback to the UI.
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String career,
    required String semester,
  }) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    final error = await _authRepository.signUpWithEmailAndPassword(
      email,
      password,
      name,
      career,
      semester,
    );

    if (error != null) {
      errorMessage = error;
    }

    isLoading = false;
    notifyListeners();
  }
}
