// lib/data/repositories/product_repository_impl.dart
import 'dart:io';
import 'package:algolia/algolia.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  static final Algolia _algolia = Algolia.init(
    applicationId: 'AAJ6U9G25X',
    apiKey: 'e1450d2b94d56f3a2bf7a7978f255be1',
  );
  ProductRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<String?> _uploadImageToFirebase(XFile image) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('product_images/$fileName');
      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final AlgoliaQuery algoliaQuery =
    _algolia.instance.index('senemarket_products_index').query(query);
    final AlgoliaQuerySnapshot snapshot = await algoliaQuery.getObjects();
    return snapshot.hits.map((hit) {
      final data = Map<String, dynamic>.from(hit.data);
      data['id'] = hit.objectID;
      return data;
    }).toList();
  }

  @override
  Future<void> addProduct({
    required List<XFile?> images,
    required String name,
    required String description,
    required String category,
    required String price,
  }) async {
    // 1. Subir todas las imágenes
    List<String> imageUrls = [];
    for (var image in images) {
      if (image != null) {
        final url = await _uploadImageToFirebase(image);
        if (url != null) {
          imageUrls.add(url);
        }
      }
    }

    if (imageUrls.isEmpty) {
      throw Exception("No se pudo subir ninguna imagen.");
    }

    // 2. Obtener el usuario actual
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No hay ningún usuario logueado.");
    }

    // 3. Obtener nombre del usuario
    final userDoc = await _db.collection('users').doc(user.uid).get();
    String sellerName = "Unknown Seller";
    if (userDoc.exists) {
      final data = userDoc.data();
      sellerName = data?['name'] ?? sellerName;
    }

    // 4. Primera imagen como portada
    final String imagePortada = imageUrls[0];

    // 5. Crear documento en "products"
    await _db.collection('products').add({
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imageUrls': imageUrls,
      'imagePortada': imagePortada,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user.uid,
      'sellerName': sellerName,
      'favoritedBy': [],
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> getProductsStream() {
    return _db
        .collection('products')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  @override
  Future<void> addProductFavorite({
    required String userId,
    required String productId,
  }) async {
    final productDocRef = _db.collection('products').doc(productId);
    await productDocRef.set({
      'favoritedBy': FieldValue.arrayUnion([userId])
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removeProductFavorite({
    required String userId,
    required String productId,
  }) async {
    final productDocRef = _db.collection('products').doc(productId);
    await productDocRef.set({
      'favoritedBy': FieldValue.arrayRemove([userId])
    }, SetOptions(merge: true));
  }
}
