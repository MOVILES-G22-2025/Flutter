import 'package:firebase_auth/firebase_auth.dart';
import 'package:senemarket/domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';

/// Connects domain logic with FirebaseAuth and Firestore
/// to manage user profile and favorites.
class UserRepositoryImpl implements UserRepository {
  final FirebaseAuth _auth;
  final UserRemoteDataSource _remote;

  UserRepositoryImpl({
    FirebaseAuth? auth,
    UserRemoteDataSource? remote,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _remote = remote ?? UserRemoteDataSource();

  /// Gets the current user's Firestore document data.
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await _remote.getUserData(user.uid);
    }
    return null;
  }

  /// Updates the current user's data in Firestore.
  @override
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _remote.updateUserData(user.uid, data);
    }
  }

  /// Adds a product to the current user's favorites.
  @override
  Future<void> addFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _remote.modifyFavorite(uid: user.uid, productId: productId, add: true);
    }
  }

  /// Removes a product from the current user's favorites.
  @override
  Future<void> removeFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _remote.modifyFavorite(uid: user.uid, productId: productId, add: false);
    }
  }
}
