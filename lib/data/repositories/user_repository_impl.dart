// lib/data/repositories/user_repository_impl.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseAuth _auth;
  final UserRemoteDataSource _remote;

  UserRepositoryImpl({
    FirebaseAuth? auth,
    UserRemoteDataSource? remote,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _remote = remote ?? UserRemoteDataSource();

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await _remote.getUserData(user.uid);
    }
    return null;
  }

  @override
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _remote.updateUserData(user.uid, data);
    }
  }

  @override
  Future<void> addFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _remote.modifyFavorite(uid: user.uid, productId: productId, add: true);
    }
  }

  @override
  Future<void> removeFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _remote.modifyFavorite(uid: user.uid, productId: productId, add: false);
    }
  }

}
