// lib/data/datasources/product_remote_data_source.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_dto.dart';

class ProductRemoteDataSource {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  ProductRemoteDataSource({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
  })  : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

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

  Future<String?> getSellerName(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()?['name'] ?? "Unknown Seller";
    }
    return "Unknown Seller";
  }

  Future<void> saveProduct(String userId, ProductDTO dto) async {
    final map = dto.toFirestore()
      ..['timestamp'] = FieldValue.serverTimestamp()
      ..['userId'] = userId;

    await _db.collection('products').add(map);
  }

  Stream<List<ProductDTO>> getProductDTOStream() {
    return _db
        .collection('products')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((query) =>
        query.docs.map((doc) => ProductDTO.fromFirestore(doc.id, doc.data())).toList());
  }

  Future<void> updateFavorites(String productId, String userId, bool add) async {
    final ref = _db.collection('products').doc(productId);
    await ref.set({
      'favoritedBy': add
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId])
    }, SetOptions(merge: true));
  }
}
