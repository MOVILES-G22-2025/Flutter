// lib/presentation/viewmodels/sign_in_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:senemarket/domain/repositories/auth_repository.dart';

class SignInViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool isLoading = false;
  String errorMessage = '';

  SignInViewModel(this._authRepository);

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
