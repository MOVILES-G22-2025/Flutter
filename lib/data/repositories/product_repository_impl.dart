// lib/data/repositories/product_repository_impl.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:algolia/algolia.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

import '../../core/services/connectivity_service.dart';
import '../../core/services/notification_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../local/database/database_helper.dart';
import '../local/models/draft_product.dart';
import '../local/models/operation.dart';
import '../local/operation_queue.dart';
import '../models/product_dto.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseAuth _auth;
  final ProductRemoteDataSource _remote;
  final Algolia _algolia;
  final FirebaseFirestore _firestore;
  final OperationQueue _opQueue;
  final ConnectivityService _connectivity;
  final DatabaseHelper _db;

  ProductRepositoryImpl({
    FirebaseAuth? auth,
    ProductRemoteDataSource? remoteDataSource,
    Algolia? algolia,
    FirebaseFirestore? firestore,
    OperationQueue? operationQueue,
    ConnectivityService? connectivityService,
    DatabaseHelper? databaseHelper,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _remote = remoteDataSource ?? ProductRemoteDataSource(),
        _algolia = algolia ??
            const Algolia.init(
              applicationId: 'AAJ6U9G25X',
              apiKey: 'e1450d2b94d56f3a2bf7a7978f255be1',
            ),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _opQueue = operationQueue ?? OperationQueue(),
        _connectivity = connectivityService ?? ConnectivityService(),
        _db = databaseHelper ?? DatabaseHelper();

  ///Búsqueda de productos en Algolia
  @override
  Future<List<Product>> searchProducts(String query) async {
    final online = await _connectivity.isOnline$.first;
    
    if (online) {
      // Online: usar Algolia y guardar en caché
      final snap = await _algolia.instance
          .index('senemarket_products_index')
          .query(query)
          .getObjects();
      
      final products = snap.hits
          .map((h) => ProductDTO.fromAlgoliaHit(h).toDomain())
          .toList();
      
      // Guardar en caché local
      for (final product in products) {
        final dto = ProductDTO.fromDomain(product);
        final map = dto.toFirestore()
          ..['id'] = dto.id
          ..['imageUrls'] = dto.imageUrls.join(',')
          ..['favoritedBy'] = jsonEncode(dto.favoritedBy)
          ..['timestamp'] = dto.timestamp?.millisecondsSinceEpoch;
        await _db.upsertCachedProduct(map);
      }
      
      return products;
    } else {
      // Offline: buscar en caché local
      final cachedProducts = await _db.getCachedProducts();
      return cachedProducts
          .where((product) {
            final name = (product['name'] as String).toLowerCase();
            final description = (product['description'] as String).toLowerCase();
            final searchLower = query.toLowerCase();
            return name.contains(searchLower) || description.contains(searchLower);
          })
          .map((product) {
            final urls = (product['imageUrls'] as String).split(',');
            final favoritedBy = (jsonDecode(product['favoritedBy'] as String) as List).cast<String>();
            final timestamp = product['timestamp'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(product['timestamp'] as int)
                : null;
            
            return Product(
              id: product['id'] as String,
              name: product['name'] as String,
              description: product['description'] as String,
              category: product['category'] as String,
              price: product['price'] as double,
              imageUrls: urls,
              sellerName: product['sellerName'] as String,
              favoritedBy: favoritedBy,
              timestamp: timestamp,
              userId: product['userId'] as String,
            );
          })
          .toList();
    }
  }

  ///Crear producto: online → Firestore, offline → pending_products
  @override
  Future<void> addProduct({
    required List<XFile?> images,
    required Product product,
  }) async {
    final user = _auth.currentUser!;
    final online = await _connectivity.isOnline$.first;
    // Usamos el id que venga o generamos uno nuevo
    final id = product.id.isNotEmpty ? product.id : const Uuid().v4();

    if (!online) {
      // Guarda en pending_products para sincronizar luego
      await _db.savePendingProduct({
        'id': id,
        'name': product.name,
        'description': product.description,
        'category': product.category,
        'price': product.price,
        'sellerName': product.sellerName,
        'imageUrls': images
            .where((e) => e != null)
            .map((e) => e!.path)
            .join(','),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': user.uid,
        'isSynced': 0,
      });
      return;
    }

    // Si hay conexión, subimos imágenes y guardamos en Firestore
    final urls = await _remote.uploadImages(images);
    if (urls.isEmpty) throw Exception("No images uploaded");

    final seller = await _remote.getSellerName(user.uid) ?? '';
    final updated = product.copyWith(
      id: id,
      imageUrls: urls,
      sellerName: seller,
      userId: user.uid,
    );
    final dto = ProductDTO.fromDomain(updated);
    await _remote.saveProduct(user.uid, dto);
  }

  /// Stream de productos: Firestore → cache local + dominio
  @override
  Stream<List<Product>> getProductsStream() {
    return _remote.getProductDTOStream().map((dtoList) async {
      // 1. Obtener productos favoritos actuales
      final userId = _auth.currentUser?.uid;
      final favoriteProducts = userId != null 
          ? await _db.getCachedFavorites(userId)
          : <Map<String, dynamic>>[];
      final favoriteIds = favoriteProducts.map((p) => p['id'] as String).toSet();

      // 2. Preparar los productos para la caché
      final productsToCache = dtoList.take(40).toList(); // Tomar los 40 más recientes
      
      // 3. Agregar productos favoritos que no estén en los 40 más recientes
      for (final dto in dtoList) {
        if (favoriteIds.contains(dto.id) && 
            !productsToCache.any((p) => p.id == dto.id)) {
          productsToCache.add(dto);
        }
      }

      // 4. Limpiar caché y guardar nuevos productos
      await _db.clearCachedProducts();
      for (final dto in productsToCache) {
        final map = dto.toFirestore()
          ..['id'] = dto.id
          ..['imageUrls'] = dto.imageUrls.join(',')
          ..['favoritedBy'] = jsonEncode(dto.favoritedBy)
          ..['timestamp'] = dto.timestamp?.millisecondsSinceEpoch;
        await _db.upsertCachedProduct(map);
      }

      // 5. Asegurarse de que los favoritos se mantengan en la caché
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final favIds = List<String>.from(userDoc.data()?['favorites'] ?? []);
        
        for (final favId in favIds) {
          final doc = await _firestore.collection('products').doc(favId).get();
          if (!doc.exists) continue;
          
          final dto = ProductDTO.fromFirestore(doc.id, doc.data()!);
          final map = dto.toFirestore()
            ..['id'] = dto.id
            ..['imageUrls'] = dto.imageUrls.join(',')
            ..['favoritedBy'] = jsonEncode(dto.favoritedBy)
            ..['timestamp'] = dto.timestamp?.millisecondsSinceEpoch;
          await _db.upsertCachedProduct(map);
        }
      }

      return dtoList.map((dto) => dto.toDomain()).toList();
    }).asyncMap((future) => future);
  }

  /// Favoritos (y encola si está offline)
  @override
  Future<void> addProductFavorite({
    required String userId,
    required String productId,
  }) async {
    // 1) Actualiza cache local
    await _updateLocalFavoritedBy(productId, userId, add: true);

    // 2) Si estoy online, disparo en Firestore; si no, encolo
    final online = await _connectivity.isOnline$.first;
    if (online) {
      await _remote.updateFavorites(productId, userId, true);
    } else {
      await _opQueue.enqueue(Operation(
        id: const Uuid().v4(),
        type: OperationType.toggleFavorite,
        payload: {'userId': userId, 'productId': productId, 'value': true},
      ));
    }
  }

  @override
  Future<void> removeProductFavorite({
    required String userId,
    required String productId,
  }) async {
    // 1) Actualiza cache local
    await _updateLocalFavoritedBy(productId, userId, add: false);

    // 2) Si estoy online, disparo en Firestore; si no, encolo
    final online = await _connectivity.isOnline$.first;
    if (online) {
      await _remote.updateFavorites(productId, userId, false);
    } else {
      await _opQueue.enqueue(Operation(
        id: const Uuid().v4(),
        type: OperationType.toggleFavorite,
        payload: {'userId': userId, 'productId': productId, 'value': false},
      ));
    }
  }

  Future<void> _updateLocalFavoritedBy(
      String productId, String userId,
      { required bool add }) async {
    final db = await _db.database;  // :contentReference[oaicite:2]{index=2}:contentReference[oaicite:3]{index=3}
    final rows = await db.query(
      'cached_products',
      columns: ['favoritedBy'],
      where: 'id = ?',
      whereArgs: [productId],
    );
    if (rows.isEmpty) return;

    final currentJson = rows.first['favoritedBy'] as String;
    final list = List<String>.from(jsonDecode(currentJson) as List);
    if (add) {
      if (!list.contains(userId)) list.add(userId);
    } else {
      list.remove(userId);
    }

    await db.update(
      'cached_products',
      {'favoritedBy': jsonEncode(list)},
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  @override
  Future<void> deleteProduct(String productId) =>
      _remote.deleteProduct(productId);

  @override
  Future<void> updateProduct({
    required String productId,
    required Product updatedProduct,
    required List<XFile?> newImages,
    required List<String> imagesToDelete,
  }) async {
    final user = _auth.currentUser!;
    final newUrls = await _remote.uploadImages(newImages);
    final merged = List<String>.from(updatedProduct.imageUrls)
      ..removeWhere(imagesToDelete.contains)
      ..addAll(newUrls);
    final dto = ProductDTO.fromDomain(
      updatedProduct.copyWith(imageUrls: merged),
    );
    await _remote.updateProduct(productId, dto);
    for (final url in imagesToDelete) {
      await _remote.deleteImageByUrl(url);
    }
  }

  @override
  Future<void> updateProductOffline({
    required String productId,
    required Product updatedProduct,
    required List<XFile?> newImages,
    required List<String> imagesToDelete,
  }) async {
    final user = _auth.currentUser!;
    
    // Guardar las imágenes nuevas localmente
    final imagePaths = newImages
        .where((e) => e != null)
        .map((e) => e!.path)
        .toList();

    // Obtener las URLs actuales y remover las que se deben eliminar
    final currentUrls = List<String>.from(updatedProduct.imageUrls)
      ..removeWhere(imagesToDelete.contains);

    // Crear el mapa del producto con las rutas locales de las imágenes
    final productMap = {
      'id': productId,
      'name': updatedProduct.name,
      'description': updatedProduct.description,
      'category': updatedProduct.category,
      'price': updatedProduct.price,
      'sellerName': updatedProduct.sellerName,
      'imageUrls': [...currentUrls, ...imagePaths].join(','),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'userId': user.uid,
      'isSynced': 0,
      'operation_type': 'edit',
      'images_to_delete': imagesToDelete.join(','), // Guardar las URLs a eliminar
    };

    // Guardar en pending_products
    await _db.savePendingProduct(productMap);

    // Actualizar también en cached_products para reflejar cambios inmediatamente
    await _db.upsertCachedProduct({
      ...productMap,
      'favoritedBy': jsonEncode(updatedProduct.favoritedBy),
    });
  }

  ///Borradores vía Hive
  @override
  Future<void> saveDraftProduct(DraftProduct draft) async {
    final box = await Hive.openBox<DraftProduct>('draft_products');
    await box.put(draft.id, draft);
  }

  ///Sincroniza los pending_products cuando recuperas conexión
  Future<void> syncOfflineProducts() async {
    final pending = await _db.getPendingProducts();
    for (final row in pending) {
      final id = row['id'] as String;
      final name = row['name'] as String;
      final desc = row['description'] as String;
      final cat = row['category'] as String;
      final rawP = row['price'];
      final price = rawP is num
          ? rawP.toDouble()
          : double.tryParse(rawP.toString()) ?? 0.0;
      final rawTs = row['timestamp'] as int;
      final ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
      final userId = row['userId'] as String;
      final rawImgs = row['imageUrls'] as String;
      final operationType = row['operation_type'] as String? ?? 'create';
      final imagesToDelete = (row['images_to_delete'] as String?)?.split(',') ?? [];
      
      // Separar URLs remotas de rutas locales
      final allPaths = rawImgs.split(',');
      final localPaths = allPaths.where((p) => p.isNotEmpty && File(p).existsSync()).toList();
      final remoteUrls = allPaths.where((p) => p.startsWith('http')).toList();
      
      if (localPaths.isEmpty && remoteUrls.isEmpty) {
        await _db.deletePendingProduct(id);
        continue;
      }
      
      final images = localPaths.map((p) => XFile(p)).toList();

      final product = Product(
        id: id,
        name: name,
        description: desc,
        category: cat,
        price: price,
        imageUrls: remoteUrls, // Mantener las URLs remotas existentes
        sellerName: '',
        favoritedBy: [],
        timestamp: ts,
        userId: userId,
      );

      try {
        if (operationType == 'edit') {
          // Para ediciones, subir nuevas imágenes y actualizar
          final newUrls = await _remote.uploadImages(images);
          final updated = product.copyWith(
            imageUrls: [...remoteUrls, ...newUrls],
          );
          final dto = ProductDTO.fromDomain(updated);
          await _remote.updateProduct(id, dto);
          
          // Eliminar imágenes marcadas para borrar
          for (final url in imagesToDelete) {
            if (url.isNotEmpty) {
              await _remote.deleteImageByUrl(url);
            }
          }
        } else {
          // Para creaciones, usar el flujo normal
          await _syncOfflineWithId(id, images, product);
        }
        await _db.deletePendingProduct(id);
      } catch (e) {
        debugPrint('❌ Failed syncing pending $id: $e');
      }
    }
  }

  /// Helper para subir offline manteniendo ID
  Future<void> _syncOfflineWithId(
      String id, List<XFile> images, Product product) async {
    final user = _auth.currentUser!;
    final urls = await _remote.uploadImages(images);
    if (urls.isEmpty) throw Exception("No images uploaded");
    final seller = await _remote.getSellerName(user.uid) ?? '';
    final updated = product.copyWith(
      imageUrls: urls,
      sellerName: seller,
      userId: user.uid,
    );
    final dto = ProductDTO.fromDomain(updated);
    await _firestore.collection('products').doc(id).set(dto.toFirestore());
  }

  /// Cola o directo para favoritos
  Future<void> _syncOrQueue({
    required OperationType type,
    required Map<String, dynamic> payload,
    required Future<void> Function() call,
  }) async {
    final online = await _connectivity.isOnline$.first;
    if (online) {
      await call();
    } else {
      await _opQueue.enqueue(Operation(
        id: const Uuid().v4(),
        type: type,
        payload: payload,
      ));
    }
  }

  /// Arranca el procesador de colas + notifica borradores pendientes
  void startQueueProcessor(NotificationService notifier) {
    _connectivity.isOnline$.listen((online) async {
      if (!online) return;
      // avisar si hay borradores
      final box = await Hive.openBox<DraftProduct>('draft_products');
      if (box.isNotEmpty) await notifier.showReminderNotification();
      // vaciar cola de favoritos
      for (final op in _opQueue.pending()) {
        if (op.type == OperationType.toggleFavorite) {
          try {
            await _remote.toggleFavoriteFromPayload(op.payload);
            await _opQueue.remove(op.id);
          } catch (_) {}
        }
      }
      // sincronizar creaciones offline
      await syncOfflineProducts();
    });
  }

  /// Analytics: clics de producto
  @override
  Future<void> logProductClick(String userId, String productId) async {
    await _firestore.collection('product-clicks').add({
      'userId': userId,
      'productId': productId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<int> getProductClickCount(String productId) async {
    // Consulta todos los docs donde productId == dado
    final snap = await _firestore
        .collection('product-clicks')
        .where('productId', isEqualTo: productId)
        .get();
    return snap.docs.length;
  }

  @override
  Future<int> fetchProductClickCount(String productId) async {
    final snap = await _firestore
        .collection('product-clicks')
        .where('productId', isEqualTo: productId)
        .get();
    return snap.docs.length;
  }

  @override
  Future<void> saveOfflineProduct(Map<String, Object> productMap) =>
      _db.savePendingProduct(productMap);

  @override
  String get currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('No authenticated user');
    return uid;
  }

  /// Getter para acceder al servicio de conectividad
  ConnectivityService get connectivity => _connectivity;

  /// Obtiene los productos de la caché local
  Future<List<Product>> getCachedProducts() async {
    final cachedProducts = await _db.getCachedProducts();
    return cachedProducts.map((product) {
      final urls = (product['imageUrls'] as String).split(',');
      final favoritedBy = (jsonDecode(product['favoritedBy'] as String) as List).cast<String>();
      final timestamp = product['timestamp'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(product['timestamp'] as int)
          : null;
      
      return Product(
        id: product['id'] as String,
        name: product['name'] as String,
        description: product['description'] as String,
        category: product['category'] as String,
        price: product['price'] as double,
        imageUrls: urls,
        sellerName: product['sellerName'] as String,
        favoritedBy: favoritedBy,
        timestamp: timestamp,
        userId: product['userId'] as String,
      );
    }).toList();
  }

  /// Obtiene los productos del usuario, online u offline
  Future<List<Product>> getUserProducts(String userId) async {
    final online = await _connectivity.isOnline$.first;
    
    if (online) {
      // Online: obtener de Firestore
      final snapshot = await _firestore
          .collection('products')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final dto = ProductDTO.fromFirestore(doc.id, doc.data());
        return dto.toDomain();
      }).toList();
    } else {
      // Offline: obtener de cached_products
      final cachedProducts = await _db.getCachedUserProducts(userId);
      return cachedProducts.map((product) {
        final urls = (product['imageUrls'] as String).split(',');
        final favoritedBy = (jsonDecode(product['favoritedBy'] as String) as List).cast<String>();
        final timestamp = product['timestamp'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(product['timestamp'] as int)
            : null;
        
        return Product(
          id: product['id'] as String,
          name: product['name'] as String,
          description: product['description'] as String,
          category: product['category'] as String,
          price: product['price'] as double,
          imageUrls: urls,
          sellerName: product['sellerName'] as String,
          favoritedBy: favoritedBy,
          timestamp: timestamp,
          userId: product['userId'] as String,
        );
      }).toList();
    }
  }
}
