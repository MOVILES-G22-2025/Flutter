import 'package:senemarket/domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/user_remote_data_source.dart';

/// Implements the AuthRepository interface.
/// Connects domain logic with remote data sources (Firebase).
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authDataSource;
  final UserRemoteDataSource _userDataSource;

  AuthRepositoryImpl({
    AuthRemoteDataSource? authDataSource,
    UserRemoteDataSource? userDataSource,
  })  : _authDataSource = authDataSource ?? AuthRemoteDataSource(),
        _userDataSource = userDataSource ?? UserRemoteDataSource();

  /// Authenticates user using email and password.
  /// Returns null if success, or an error message if failed.
  @override
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    final user = await _authDataSource.signInWithEmail(email, password);
    if (user == null) {
      return 'Incorrect credentials.';
    }

    await _userDataSource.logUserEvent(user.uid, 'signin');

    return null;
  }

  /// Creates a new user and stores their profile in Firestore.
  /// Returns null if success, or an error message if failed.
  @override
  Future<String?> signUpWithEmailAndPassword(
      String email,
      String password,
      String name,
      String career,
      String semester,
      ) async {
    final user = await _authDataSource.signUpWithEmail(email, password);
    if (user == null) {
      return 'Registration failed.';
    }

    await _userDataSource.createUserDocument(
      uid: user.uid,
      name: name,
      career: career,
      semester: semester,
      email: email,
    );

    return null;
  }

  /// Ends the current user session.
  @override
  Future<void> signOut() async {
    await _authDataSource.signOut();
  }

  /// Returns true if a user is signed in.
  @override
  bool get isAuthenticated => _authDataSource.isAuthenticated;
}
