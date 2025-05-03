// lib/data/repositories/product_repository_impl.dart

import 'dart:async';
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
    final snap = await _algolia.instance
        .index('senemarket_products_index')
        .query(query)
        .getObjects();
    return snap.hits
        .map((h) => ProductDTO.fromAlgoliaHit(h).toDomain())
        .toList();
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
    return _remote.getProductDTOStream().map((dtoList) {
      for (final dto in dtoList) {
        // Preparamos el map para cached_products:
        final map = dto.toFirestore()
          ..['id'] = dto.id
          ..['imageUrls'] = dto.imageUrls.join(',')
          ..['timestamp'] = dto.timestamp?.millisecondsSinceEpoch;
        _db.upsertCachedProduct(map);
      }
      return dtoList.map((dto) => dto.toDomain()).toList();
    });
  }

  /// 4️⃣ Favoritos (y encola si está offline)
  @override
  Future<void> addProductFavorite({
    required String userId,
    required String productId,
  }) =>
      _syncOrQueue(
        type: OperationType.toggleFavorite,
        payload: {'userId': userId, 'productId': productId, 'value': true},
        call: () => _remote.updateFavorites(productId, userId, true),
      );

  @override
  Future<void> removeProductFavorite({
    required String userId,
    required String productId,
  }) =>
      _syncOrQueue(
        type: OperationType.toggleFavorite,
        payload: {'userId': userId, 'productId': productId, 'value': false},
        call: () => _remote.updateFavorites(productId, userId, false),
      );

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


}
