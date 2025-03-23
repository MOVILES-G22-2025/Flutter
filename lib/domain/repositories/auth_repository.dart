/// Defines the contract for authentication logic in the domain layer.
/// Implementations should handle how authentication is done (e.g., Firebase, API, etc.).
abstract class AuthRepository {
  /// Tries to sign in the user with email and password.
  /// Returns an error message if failed, or null if success.
  Future<String?> signInWithEmailAndPassword(String email, String password);

  /// Creates a new user account and profile with the provided data.
  /// Returns an error message if failed, or null if success.
  Future<String?> signUpWithEmailAndPassword(
      String email,
      String password,
      String name,
      String career,
      String semester,
      );

  /// Signs out the current user.
  Future<void> signOut();

  /// Returns true if a user is currently signed in.
  bool get isAuthenticated;
}
