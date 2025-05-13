import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final userId = userCredential.user?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'name': name,
          'email': email,
          'career': career,
          'semester': semester,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered.';
      } else {
        errorMessage = e.message ?? 'Unknown error';
      }
    } catch (e) {
      errorMessage = 'Something went wrong.';
    }

    isLoading = false;
    notifyListeners();
  }
}
