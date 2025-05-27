import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import '../../../../core/services/otp_service.dart';
import '../../../../data/local/models/otp_info.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../data/local/database/services/sync_service.dart';

/// ViewModel that manages sign-in logic and state for the UI.
/// Delegates authentication to the AuthRepository.
class SignInViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SyncService _syncService = SyncService();

  bool isLoading = false;
  String errorMessage = '';

  SignInViewModel(this._authRepository);

  /// Tries to sign in with email and password.
  /// Shows loading and error state to the UI.
  Future<bool> signIn(String email, String password) async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    final error = await _authRepository.signInWithEmailAndPassword(email, password);

    if (error != null) {
      errorMessage = error;
      isLoading = false;
      notifyListeners();
      return false;
    }

    //Esperar hasta que FirebaseAuth detecte el usuario autenticado
    await FirebaseAuth.instance.authStateChanges().firstWhere((user) => user != null);

    await _syncService.sincronizarUsuarioPorEmail(email);

    try {
      if (!Hive.isBoxOpen('otp_info')) {
        await Hive.openBox<OtpInfo>('otp_info');
      }

      await OtpService.generateAndSendOtp(email);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Error sending the code. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}