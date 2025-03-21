import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProductFacade {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Sube una imagen a Firebase Storage y retorna la URL pública
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

  // CREA UN NUEVO PRODUCRO EN LA COLECCION "PRODUCTS"
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

    // 3. Obtener el nombre del usuario desde la colección "users"
    final userDoc = await _db.collection('users').doc(user.uid).get();
    String sellerName = "Unknown Seller";
    if (userDoc.exists) {
      final data = userDoc.data();
      sellerName = data?['name'] ?? sellerName;
    }

    // 4. Elegir la primera imagen como "portada"
    final String imagePortada = imageUrls[0];

    // 5. Crear el documento en "products"
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

  // DEVUELVE UN STREAM DE PRODUCTOS ORDENADOS POR TIMESTAMP
  Stream<List<Map<String, dynamic>>> getProductsStream() {
    return _db
        .collection('products')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // AGREGA EL ID DEL USUARIO AL ARRAY 'favoritedBy' DEL PRODUCTO
  Future<void> addProductFavorite({
    required String userId,
    required String productId,
  }) async {
    final productDocRef = _db.collection('products').doc(productId);
    await productDocRef.set({
      'favoritedBy': FieldValue.arrayUnion([userId])
    }, SetOptions(merge: true));
  }

  // REMUEVE EL ID DEL USUARIO DEL ARRAY 'favoritedBy' DEL PRODUCTO
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

