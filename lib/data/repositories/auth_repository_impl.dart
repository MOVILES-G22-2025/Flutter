// lib/data/repositories/auth_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:senemarket/domain/repositories/auth_repository.dart';
import '../services/auth_service.dart'; // singleton aquí

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService = AuthService(); // Uso del singleton

  @override
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    final user = await _authService.signInWithEmail(email, password);
    if (user == null) {
      return 'Incorrect credentials.';
    }
    return null;
  }

  @override
  Future<String?> signUpWithEmailAndPassword(
      String email,
      String password,
      String name,
      String career,
      String semester,
      ) async {
    final user = await _authService.signUpWithEmail(email, password);
    if (user == null) {
      return 'Registration failed.';
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': name,
      'career': career,
      'semester': semester,
      'email': email,
      'favorites': [],
    });

    return null;
  }
}
