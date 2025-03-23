import 'package:firebase_auth/firebase_auth.dart';

/// Handles all authentication logic using FirebaseAuth.
/// This class is used to connect to Firebase to sign in, sign up and sign out users.
class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  /// Singleton instance to avoid creating multiple FirebaseAuth instances.
  static final AuthRemoteDataSource _instance =
  AuthRemoteDataSource._internal(FirebaseAuth.instance);

  /// Private constructor for singleton pattern.
  AuthRemoteDataSource._internal(this._firebaseAuth);

  /// Factory to return the same instance every time.
  factory AuthRemoteDataSource() {
    return _instance;
  }

  /// Returns the current signed in user.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Sign in a user with email and password.
  /// Returns a User if success, or null if failed.
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

  /// Register a new user with email and password.
  /// Returns a User if success, or null if failed.
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

  /// Sign out the current user.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Check if a user is currently authenticated (logged in).
  bool get isAuthenticated => currentUser != null;
}
