import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:senemarket/domain/repositories/favorites_repository.dart';

/// Handles the logic to add and remove products from favorites
/// by interacting directly with Firestore.
class FavoritesRepositoryImpl implements FavoritesRepository {
  final FirebaseFirestore _firestore;

  FavoritesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Adds the product ID to the user's favorites list
  /// and adds the user ID to the product's favoritedBy list.
  @override
  Future<void> addProductToFavorites(String userId, String productId) async {
    await _firestore.collection('users').doc(userId).set({
      'favorites': FieldValue.arrayUnion([productId])
    }, SetOptions(merge: true));

    await _firestore.collection('products').doc(productId).set({
      'favoritedBy': FieldValue.arrayUnion([userId])
    }, SetOptions(merge: true));
  }

  /// Removes the product ID from the user's favorites list
  /// and removes the user ID from the product's favoritedBy list.
  @override
  Future<void> removeProductFromFavorites(String userId, String productId) async {
    await _firestore.collection('users').doc(userId).set({
      'favorites': FieldValue.arrayRemove([productId])
    }, SetOptions(merge: true));

    await _firestore.collection('products').doc(productId).set({
      'favoritedBy': FieldValue.arrayRemove([userId])
    }, SetOptions(merge: true));
  }
}
