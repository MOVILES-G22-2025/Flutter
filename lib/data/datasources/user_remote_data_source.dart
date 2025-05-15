import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles reading and writing user data to Firestore.
class UserRemoteDataSource {
  final FirebaseFirestore _firestore;

  UserRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Gets the user document data by UID.
  /// Returns null if the user does not exist.
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return doc.data();
    return null;
  }

  /// Creates a new user document in Firestore after sign up.
  /// Initializes favorites list as empty.
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

    //Registrar el evento de creacion de cuenta
    await logUserEvent(uid, 'signup');
  }

  /// Updates user data with merge option to preserve existing fields.
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  /// Adds or removes a product from the user's favorites list.
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

  //Funcion para registrar eventos
  Future<void> logUserEvent(String uid, String event) async {
    if (uid.isEmpty) return;

    try {
      await _firestore.collection('user-logs').add({
        'uid': uid,
        'event': event,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging user event: $e');
    }
  }
}
