import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFacade {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // OBTIENE LOS DATOS ADICIONALES DESDE LA COLECCION 'users'
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
      await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  // ACTUALIZA LOS DATOS DEL USUARIO EN FIRESTORE
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
    }
  }

  // AGREGA UN PRODUCTO A LA LISTA DE FAVORITOS DEL USUARIO
  Future<void> addFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'favorites': FieldValue.arrayUnion([productId])
      }, SetOptions(merge: true));
    }
  }

  // REMUEVE UN PRODUCTO DE LA LISTA DE FAVORITOS DEL USUARIO
  Future<void> removeFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'favorites': FieldValue.arrayRemove([productId])
      }, SetOptions(merge: true));
    }
  }
}
