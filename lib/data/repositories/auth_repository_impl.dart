// lib/data/repositories/auth_repository_impl.dart

import 'package:senemarket/domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/user_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authDataSource;
  final UserRemoteDataSource _userDataSource;

  AuthRepositoryImpl({
    AuthRemoteDataSource? authDataSource,
    UserRemoteDataSource? userDataSource,
  })  : _authDataSource = authDataSource ?? AuthRemoteDataSource(),
        _userDataSource = userDataSource ?? UserRemoteDataSource();

  @override
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    final user = await _authDataSource.signInWithEmail(email, password);
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

  @override
  Future<void> signOut() async {
    await _authDataSource.signOut();
  }

  @override
  bool get isAuthenticated => _authDataSource.isAuthenticated;
}
