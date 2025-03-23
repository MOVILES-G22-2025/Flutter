// lib/data/repositories/favorites_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:senemarket/domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FirebaseFirestore _firestore;

  FavoritesRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> addProductToFavorites(String userId, String productId) async {
    await _firestore.collection('users').doc(userId).set({
      'favorites': FieldValue.arrayUnion([productId])
    }, SetOptions(merge: true));

    await _firestore.collection('products').doc(productId).set({
      'favoritedBy': FieldValue.arrayUnion([userId])
    }, SetOptions(merge: true));
  }

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
