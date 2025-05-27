import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/services/otp_service.dart';
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

    final result = await _authRepository.signUpWithEmailAndPassword(
      email,
      password,
      name,
      career,
      semester,
    );

    if (result != null) {
      errorMessage = result;
    } else {
      await OtpService.generateAndSendOtp(email); // Envía OTP tras registro
    }

    isLoading = false;
    notifyListeners();
  }
}
