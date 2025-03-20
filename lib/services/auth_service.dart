import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  //Single static instance
  static final AuthService _instance = AuthService._internal();

  //Private constructor to prevent additional instances from being created
  AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Get the current user
  User? get currentUser => _auth.currentUser;

  //Register user
  Future<String?> signUpWithEmailAndPassword(String email, String password,
      String name, String career, String semester) async {
    if (!email.endsWith('@uniandes.edu.co')) {
      return 'You must use an @uniandes.edu.co email';
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //Save additional data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'career': career,
        'semester': semester,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Error registering user';
    }
  }

  //Sign in
  Future<String?> signInWithEmailAndPassword(
      String email, String password) async {
    if (!email.endsWith('@uniandes.edu.co')) {
      return 'You must use an @uniandes.edu.co email';
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'The user is not registered';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password';
      } else {
        return e.message ?? 'Login error';
      }
    }
  }

  //Method to log out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
