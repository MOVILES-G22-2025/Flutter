abstract class AuthRepository {
  Future<String?> signInWithEmailAndPassword(String email, String password);
  Future<String?> signUpWithEmailAndPassword(
      String email,
      String password,
      String name,
      String career,
      String semester,
      );
  Future<void> signOut();
  bool get isAuthenticated;
}
