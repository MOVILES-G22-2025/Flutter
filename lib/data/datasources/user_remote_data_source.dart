// lib/data/datasources/user_remote_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return doc.data();
    return null;
  }
  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String career,
    required String semester,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'career': career,
      'semester': semester,
      'email': email,
      'favorites': [],
    });
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> modifyFavorite({
    required String uid,
    required String productId,
    required bool add,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'favorites': add
          ? FieldValue.arrayUnion([productId])
          : FieldValue.arrayRemove([productId])
    }, SetOptions(merge: true));
  }


}
