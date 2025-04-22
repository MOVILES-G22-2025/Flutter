import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_dto.dart';

/// Handles all communication with Firestore and Firebase Storage
/// for uploading product images, saving product data, and managing favorites.
class ProductRemoteDataSource {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  ProductRemoteDataSource({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
  })  : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Uploads a list of selected images to Firebase Storage.
  /// Returns a list of image URLs after upload.
  Future<List<String>> uploadImages(List<XFile?> images) async {
    final imageUrls = <String>[];
    for (final image in images) {
      if (image != null) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = _storage.ref().child('product_images/$fileName');
        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }
    }
    return imageUrls;
  }

  /// Gets the seller's name from the user document by user ID.
  /// Returns "Unknown Seller" if the name doesn't exist.
  Future<String?> getSellerName(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()?['name'] ?? "Unknown Seller";
    }
    return "Unknown Seller";
  }

  /// Saves the product to Firestore with a server timestamp and user ID.
  Future<void> saveProduct(String userId, ProductDTO dto) async {
    final map = dto.toFirestore()
      ..['timestamp'] = FieldValue.serverTimestamp()
      ..['userId'] = userId;

    await _db.collection('products').add(map);
  }

  /// Returns a live stream of all products ordered by most recent.
  Stream<List<ProductDTO>> getProductDTOStream() {
    return _db
        .collection('products')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((query) =>
        query.docs.map((doc) => ProductDTO.fromFirestore(doc.id, doc.data())).toList());
  }

  /// Adds or removes the user from the product's 'favoritedBy' list.
  Future<void> updateFavorites(String productId, String userId, bool add) async {
    final productRef = _db.collection('products').doc(productId);
    final userRef = _db.collection('users').doc(userId);

    await Future.wait([
      productRef.set({
        'favoritedBy': add
            ? FieldValue.arrayUnion([userId])
            : FieldValue.arrayRemove([userId])
      }, SetOptions(merge: true)),
      userRef.set({
        'favorites': add
            ? FieldValue.arrayUnion([productId])
            : FieldValue.arrayRemove([productId])
      }, SetOptions(merge: true)),
    ]);
  }

  /// Deletes a product from Firestore by its ID.
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  /// Updates a product with new data and images.
  Future<void> updateProduct(String productId, ProductDTO dto) async {
    final map = dto.toFirestore();
    await _db.collection('products').doc(productId).update(map);
  }

  /// Deletes an image from Firebase Storage by its URL.
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image from Firebase Storage: $e');
    }
  }

  /// Aplica una operación de favorito usando un payload genérico
  Future<void> toggleFavoriteFromPayload(Map<String, dynamic> payload) async {
    final productId = payload['productId'] as String;
    final userId = payload['userId'] as String;
    final add = payload['value'] as bool;

    await updateFavorites(productId, userId, add);
  }

}
