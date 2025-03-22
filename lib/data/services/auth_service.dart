import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Instancia privada de FirebaseAuth
  final FirebaseAuth _firebaseAuth;

  // Singleton privado estático
  static final AuthService _instance = AuthService._internal(FirebaseAuth.instance);

  // Constructor interno privado
  AuthService._internal(this._firebaseAuth);

  factory AuthService() {
    return _instance;
  }

  // Acceso directo a currentUser
  User? get currentUser => _firebaseAuth.currentUser;

  // Sign In con email y contraseña
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

  // registro (Sign Up)
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

  // cerrar sesión (Sign Out)
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Verificar si usuario está autenticado
  bool get isAuthenticated => currentUser != null;
}
