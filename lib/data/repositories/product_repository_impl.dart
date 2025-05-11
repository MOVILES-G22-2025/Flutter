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
            Algolia.init(
              applicationId: 'AAJ6U9G25X',
              apiKey: 'e1450d2b94d56f3a2bf7a7978f255be1',
            ),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _opQueue = operationQueue ?? OperationQueue(),
        _connectivity = connectivityService ?? ConnectivityService(),
        _db = databaseHelper ?? DatabaseHelper();

  /// 1️⃣ Búsqueda de productos en Algolia
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

  /// 2️⃣ Crear producto: online → Firestore, offline → pending_products
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

  /// 3️⃣ Stream de productos: Firestore → cache local + dominio
  @override
  Stream<List<Product>> getProductsStream() {
    return _remote.getProductDTOStream().map((dtoList) async {
      // 1. Obtener productos favoritos actuales
      final userId = _auth.currentUser?.uid;
      final favoriteProducts = userId != null 
          ? await _db.getCachedFavorites(userId)
          : <Map<String, dynamic>>[];
      final favoriteIds = favoriteProducts.map((p) => p['id'] as String).toSet();

      // 2. Filtrar productos que no son del usuario actual
      final otherUsersProducts = dtoList.where((dto) => dto.userId != userId).toList();
      
      // 3. Preparar los nuevos productos para la caché
      final productsToCache = otherUsersProducts.take(40).toList(); // Tomar solo los 40 más recientes
      
      // 4. Agregar productos favoritos que no estén en los 40 más recientes
      for (final dto in otherUsersProducts) {
        if (favoriteIds.contains(dto.id) && 
            !productsToCache.any((p) => p.id == dto.id)) {
          productsToCache.add(dto);
        }
      }

      // 5. Limpiar caché y guardar nuevos productos
      await _db.clearCachedProducts();
      for (final dto in productsToCache) {
        final map = dto.toFirestore()
          ..['id'] = dto.id
          ..['imageUrls'] = dto.imageUrls.join(',')
          ..['favoritedBy'] = jsonEncode(dto.favoritedBy)
          ..['timestamp'] = dto.timestamp?.millisecondsSinceEpoch;
        await _db.upsertCachedProduct(map);
      }

      return dtoList.map((dto) => dto.toDomain()).toList();
    }).asyncMap((future) => future);
  }

  /// 4️⃣ Favoritos (y encola si está offline)
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

  /// 5️⃣ Borradores vía Hive
  @override
  Future<void> saveDraftProduct(DraftProduct draft) async {
    final box = await Hive.openBox<DraftProduct>('draft_products');
    await box.put(draft.id, draft);
  }

  /// 6️⃣ Sincroniza los pending_products cuando recuperas conexión
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
      final paths = rawImgs
          .split(',')
          .where((p) => p.isNotEmpty && File(p).existsSync())
          .toList();
      if (paths.isEmpty) {
        await _db.deletePendingProduct(id);
        continue;
      }
      final images = paths.map((p) => XFile(p)).toList();

      final product = Product(
        id: id,
        name: name,
        description: desc,
        category: cat,
        price: price,
        imageUrls: [],
        sellerName: '',
        favoritedBy: [],
        timestamp: ts,
        userId: userId,
      );

      try {
        await _syncOfflineWithId(id, images, product);
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
}
