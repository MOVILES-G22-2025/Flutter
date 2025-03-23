import 'package:flutter/cupertino.dart';

import '../../../../domain/repositories/auth_repository.dart';

class SignUpViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool isLoading = false;
  String errorMessage = '';

  SignUpViewModel(this._authRepository);

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
