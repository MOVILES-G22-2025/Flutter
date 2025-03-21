import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:algolia/algolia.dart';

import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';
import 'package:senemarket/data/dto/product_dto.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  // Instancia de Algolia (para búsqueda)
  static final Algolia _algolia = Algolia.init(
    applicationId: 'AAJ6U9G25X', // Reemplaza con tu ID
    apiKey: 'e1450d2b94d56f3a2bf7a7978f255be1', // Reemplaza con tu key
  );

  ProductRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  //====================
  // 1) SEARCH PRODUCTS
  //====================
  @override
  Future<List<Product>> searchProducts(String query) async {
    // Hacemos la consulta a Algolia
    final AlgoliaQuery algoliaQuery =
    _algolia.instance.index('senemarket_products_index').query(query);
    final AlgoliaQuerySnapshot snapshot = await algoliaQuery.getObjects();

    // Convertimos cada hit -> ProductDTO -> Product
    final products = snapshot.hits.map((hit) {
      final dto = ProductDTO.fromAlgoliaHit(hit);
      return dto.toDomain();
    }).toList();

    return products;
  }

  //====================
  // 2) ADD PRODUCT
  //====================
  @override
  Future<void> addProduct({
    required List<XFile?> images,
    required Product product,
  }) async {
    // 1. Subir todas las imágenes a Firebase Storage
    final imageUrls = <String>[];
    for (final image in images) {
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

    // 2. Obtener usuario actual
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

    // 4. Creamos un Product con los nuevos datos
    final updatedProduct = product.copyWith(
      imageUrls: imageUrls,
      sellerName: sellerName,
    );

    // 5. Convertir a DTO y map para Firestore
    final dto = ProductDTO.fromDomain(updatedProduct);
    final mapData = dto.toFirestore()
      ..['timestamp'] = FieldValue.serverTimestamp()
      ..['userId'] = user.uid;

    // 6. Crear documento en "products"
    await _db.collection('products').add(mapData);
  }

  //====================
  // 3) GET PRODUCTS STREAM
  //====================
  @override
  Stream<List<Product>> getProductsStream() {
    return _db
        .collection('products')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Convertimos doc => ProductDTO => Product
        final dto = ProductDTO.fromFirestore(doc.id, data);
        return dto.toDomain();
      }).toList();
    });
  }

  //====================
  // 4) FAVORITES
  //====================
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

  //====================
  // MÉTODOS PRIVADOS
  //====================
  Future<String?> _uploadImageToFirebase(XFile image) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = _storage.ref().child('product_images/$fileName');
      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }
}
