import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:algolia/algolia.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/connectivity_service.dart';
import '../../core/services/notification_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../local/models/draft_product.dart';
import '../local/models/operation.dart';
import '../local/operation_queue.dart';
import '../models/product_dto.dart';
import '../datasources/product_remote_data_source.dart';
import '../local/database/database_helper.dart';
import 'package:uuid/uuid.dart';

/// Implementación de ProductRepository con sincronización eventual
class ProductRepositoryImpl implements ProductRepository {
  final FirebaseAuth _auth;
  final ProductRemoteDataSource _remoteDataSource;
  final Algolia _algolia;
  final FirebaseFirestore _firestore;
  final OperationQueue _operationQueue;
  final ConnectivityService _connectivityService;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  ProductRepositoryImpl({
    FirebaseAuth? auth,
    ProductRemoteDataSource? remoteDataSource,
    Algolia? algolia,
    FirebaseFirestore? firestore,
    OperationQueue? operationQueue,
    ConnectivityService? connectivityService,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource(),
        _algolia = algolia ??
            Algolia.init(
              applicationId: 'AAJ6U9G25X',
              apiKey: 'e1450d2b94d56f3a2bf7a7978f255be1',
            ),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _operationQueue = operationQueue ?? OperationQueue(),
        _connectivityService = connectivityService ?? ConnectivityService();

  /// Busca productos en Algolia
  @override
  Future<List<Product>> searchProducts(String query) async {
    final snapshot = await _algolia.instance
        .index('senemarket_products_index')
        .query(query)
        .getObjects();
    return snapshot.hits
        .map((hit) => ProductDTO.fromAlgoliaHit(hit).toDomain())
        .toList();
  }

  /// Añade producto: online → Firebase, offline → SQLite local
  @override
  Future<void> addProduct({
    required List<XFile?> images,
    required Product product,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final online = await _connectivityService.isOnline$.first;
    if (!online) {
      // Guardar producto completamente en DB local
      final id = const Uuid().v4();
      final imagePaths = images.where((e) => e != null).map((e) => e!.path).toList();
      final map = {
        'id': id,
        'category': product.category,
        'description': product.description,
        'imageUrls': imagePaths.join(','),
        'name': product.name,
        'price': product.price,
        'sellerName': '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': user.uid,
        'isSynced': 0,
      };
      await _dbHelper.saveOfflineProduct(map);
      return;
    }

    // Si hay conexión, subir normalmente
    final imageUrls = await _remoteDataSource.uploadImages(images);
    if (imageUrls.isEmpty) throw Exception("No images uploaded");

    final sellerName = await _remoteDataSource.getSellerName(user.uid) ?? '';
    final updatedProduct = product.copyWith(
      imageUrls: imageUrls,
      sellerName: sellerName,
      userId: user.uid,
    );
    final dto = ProductDTO.fromDomain(updatedProduct);
    await _remoteDataSource.saveProduct(user.uid, dto);
  }

  /// Stream de productos desde Firestore
  @override
  Stream<List<Product>> getProductsStream() {
    return _remoteDataSource
        .getProductDTOStream()
        .map((list) => list.map((dto) => dto.toDomain()).toList());
  }

  /// Favoritos con cola de operaciones
  @override
  Future<void> addProductFavorite({required String userId, required String productId}) async {
    await _syncOrQueue(
      type: OperationType.toggleFavorite,
      payload: {'userId': userId, 'productId': productId, 'value': true},
      call: () => _remoteDataSource.updateFavorites(productId, userId, true),
    );
  }
  @override
  Future<void> removeProductFavorite({required String userId, required String productId}) async {
    await _syncOrQueue(
      type: OperationType.toggleFavorite,
      payload: {'userId': userId, 'productId': productId, 'value': false},
      call: () => _remoteDataSource.updateFavorites(productId, userId, false),
    );
  }

  @override
  Future<void> deleteProduct(String productId) => _remoteDataSource.deleteProduct(productId);

  @override
  Future<void> updateProduct({
    required String productId,
    required Product updatedProduct,
    required List<XFile?> newImages,
    required List<String> imagesToDelete,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    final newImageUrls = await _remoteDataSource.uploadImages(newImages);
    final updatedImageUrls = List<String>.from(updatedProduct.imageUrls)
      ..removeWhere((url) => imagesToDelete.contains(url))
      ..addAll(newImageUrls);
    final dto = ProductDTO.fromDomain(updatedProduct.copyWith(imageUrls: updatedImageUrls));
    await _remoteDataSource.updateProduct(productId, dto);
    for (final url in imagesToDelete) {
      await _remoteDataSource.deleteImageByUrl(url);
    }
  }

  /// Convierte un Product en Draft y lo guarda en Hive
  @override
  Future<void> saveDraftProduct(DraftProduct draft) async {
    final box = await Hive.openBox<DraftProduct>('draft_products');
    await box.put(draft.id, draft);
    print('✏️ Draft guardado: ${draft.id}');
  }

  /// Obtiene mapas de productos no sincronizados
  Future<List<Map<String, dynamic>>> getUnsyncedProducts() => _dbHelper.getUnsyncedProducts();

  /// Marca un producto local como sincronizado
  Future<void> markAsSynced(String id) => _dbHelper.markAsSynced(id);

  /// Sincroniza todos los productos offline cuando haya conexión
  Future<void> syncOfflineProducts() async {
    final unsynced = await _dbHelper.getUnsyncedProducts();

    for (final row in unsynced) {
      // 1) Normalizar y extraer de forma segura cada campo
      final id = row['id'] as String? ?? const Uuid().v4();
      final name = (row['name'] as String?) ?? '';
      final description = (row['description'] as String?) ?? '';
      final category = (row['category'] as String?) ?? '';
      final rawPrice = row['price'];
      final price = (rawPrice is num)
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice.toString()) ?? 0.0;
      final rawTs = row['timestamp'];
      final timestamp = (rawTs is int)
          ? DateTime.fromMillisecondsSinceEpoch(rawTs)
          : DateTime.now();
      final userId = (row['userId'] as String?) ?? '';
      final rawImages = row['imageUrls'] as String?;  // Puede ser null

      // 2) Convertir la cadena en lista y filtrar solo las rutas válidas
      final imagePaths = <String>[];
      if (rawImages != null && rawImages.isNotEmpty) {
        for (final p in rawImages.split(',')) {
          if (File(p).existsSync()) {
            imagePaths.add(p);
          } else {
            print('🔍 Ruta no existe, se salta: $p');
          }
        }
      }

      // 3) Si no hay imágenes válidas, marcamos sincronizado y seguimos
      if (imagePaths.isEmpty) {
        print('⚠️ No hay imágenes válidas para $id. Marcando como sincronizado.');
        await _dbHelper.markAsSynced(id);
        continue;
      }

      // 4) Generar lista de XFile
      final images = imagePaths.map((p) => XFile(p)).toList();

      // 5) Reconstruir entidad Product
      final product = Product(
        id: id,
        name: name,
        description: description,
        category: category,
        price: price,
        imageUrls: [],       // Se rellenan tras subir
        sellerName: '',
        favoritedBy: [],
        timestamp: timestamp,
        userId: userId,
      );

      try {
        // 6) Ahora sí subir las imágenes y el producto a Firebase
        await addProduct(images: images, product: product);
        // 7) Marcar como sincronizado
        await _dbHelper.markAsSynced(id);
        print('✅ Producto $id sincronizado correctamente.');
      } catch (e) {
        print('❌ Error al sincronizar offline product $id: $e');
        // No lo marcamos como sincronizado, para reintentar más tarde
      }
    }
  }

  /// Cola de operaciones para favoritos
  Future<void> _syncOrQueue({required OperationType type, required Map<String, dynamic> payload, required Future<void> Function() call}) async {
    final online = await _connectivityService.isOnline$.first;
    if (online) {
      await call();
    } else {
      final op = Operation(id: const Uuid().v4(), type: type, payload: payload);
      await _operationQueue.enqueue(op);
    }
  }

  /// Procesa cola de favoritos y drafts al recuperar conexión
  void startQueueProcessor(NotificationService notificationService) {
    _connectivityService.isOnline$.listen((online) async {
      if (!online) return;
      // Notificar drafts pendientes
      final box = await Hive.openBox<DraftProduct>('draft_products');
      if (box.isNotEmpty) {
        await notificationService.showReminderNotification();
      }
      // Procesar favoritos en cola
      final ops = _operationQueue.pending();
      for (final op in ops) {
        if (op.type == OperationType.toggleFavorite) {
          try {
            await _remoteDataSource.toggleFavoriteFromPayload(op.payload);
            await _operationQueue.remove(op.id);
          } catch (_) {}
        }
      }
      // Sincronizar productos offline
      await syncOfflineProducts();
    });
  }

  /// Registra en Firestore un “click” sobre un producto (por analytics)
  @override
  Future<void> logProductClick(String userId, String productId) async {
    try {
      await _firestore.collection('product-clics').add({
        'userId': userId,
        'productId': productId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging product click: $e');
      rethrow;
    }
  }

  /// Guarda un producto completo en la base local (SQLite) para sincronizar luego
  @override
  Future<void> saveOfflineProduct(Map<String, Object> productMap) async {
    try {
      await _dbHelper.saveOfflineProduct(productMap);
    } catch (e) {
      print('Error saving product offline: $e');
      rethrow;
    }
  }


  @override
  String get currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('No hay usuario autenticado');
      // —o— return '';
    }
    return uid;
  }

}
