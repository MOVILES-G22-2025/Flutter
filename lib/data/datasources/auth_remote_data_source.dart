// lib/data/datasources/auth_remote_data_source.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  static final AuthRemoteDataSource _instance =
  AuthRemoteDataSource._internal(FirebaseAuth.instance);

  AuthRemoteDataSource._internal(this._firebaseAuth);

  factory AuthRemoteDataSource() {
    return _instance;
  }

  User? get currentUser => _firebaseAuth.currentUser;

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credentials = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credentials.user;
    } catch (e) {
      print("Error signing in: $e");
      return null;
    }
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final credentials = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credentials.user;
    } catch (e) {
      print("Error signing up: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  bool get isAuthenticated => currentUser != null;
}
