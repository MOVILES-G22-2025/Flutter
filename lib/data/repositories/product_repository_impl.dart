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
    if (user == null) throw Exception("User must be logged in");

    final online = await _connectivityService.isOnline$.first;
    if (!online) {
      // — SIN CONEXIÓN → guardamos todo el producto localmente con su propio ID
      final id = const Uuid().v4();
      final imagePaths = images.where((e) => e != null).map((e) => e!.path).join(',');
      await _dbHelper.saveOfflineProduct({
        'id':         id,
        'name':       product.name,
        'description':product.description,
        'category':   product.category,
        'price':      product.price,
        'imageUrls':  imagePaths,
        'sellerName': '',
        'timestamp':  DateTime.now().millisecondsSinceEpoch,
        'userId':     user.uid,
        'isSynced':   0,
      });
      return;
    }

    // — CONEXIÓN → subida normal de imágenes + Firestore
    final urls = await _remoteDataSource.uploadImages(images);
    if (urls.isEmpty) throw Exception("No images uploaded");

    final seller = await _remoteDataSource.getSellerName(user.uid) ?? '';
    final updated = product.copyWith(
      imageUrls: urls,
      sellerName: seller,
      userId: user.uid,
    );
    final dto = ProductDTO.fromDomain(updated);

    // Usa .add(...) para nuevos productos online
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
    final rows = await _dbHelper.getUnsyncedProducts();
    for (final row in rows) {
      final id        = row['id'] as String;
      final name      = row['name'] as String;
      final desc      = row['description'] as String;
      final cat       = row['category'] as String;
      final rawPrice  = row['price'];
      final price     = rawPrice is num ? rawPrice.toDouble() : double.parse(rawPrice.toString());
      final rawTs     = row['timestamp'] as int;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(rawTs);
      final userId    = row['userId'] as String;
      final rawImgs   = row['imageUrls'] as String;

      // reconstruir lista de XFile sólo con rutas válidas
      final paths = rawImgs.split(',').where((p) => File(p).existsSync()).toList();
      if (paths.isEmpty) {
        // si no hay imágenes, lo borramos directamente
        await _dbHelper.deleteOfflineProduct(id);
        continue;
      }

      // crear el domain object
      final product = Product(
        id:          id,
        name:        name,
        description: desc,
        category:    cat,
        price:       price,
        imageUrls:   [],
        sellerName:  '',
        favoritedBy: [],
        timestamp:   timestamp,
        userId:      userId,
      );

      try {
        // sube usando el mismo ID local:
        await _syncOfflineWithId(id, paths.map((p) => XFile(p)).toList(), product);
        // una vez subido, eliminamos el registro local
        await _dbHelper.deleteOfflineProduct(id);
      } catch (e) {
        print('❌ Failed to sync $id: $e');
        // lo dejamos para reintentar más tarde
      }
    }
  }

  /// helper que sube el producto offline **manteniendo** su ID
  Future<void> _syncOfflineWithId(
      String id,
      List<XFile?> images,
      Product product,
      ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User must be logged in");

    // 1) subir imágenes
    final urls = await _remoteDataSource.uploadImages(images);
    if (urls.isEmpty) throw Exception("No images uploaded");

    // 2) reconstruir producto con URLs e ID
    final seller = await _remoteDataSource.getSellerName(user.uid) ?? '';
    final updated = product.copyWith(
      id:        id,
      imageUrls: urls,
      sellerName: seller,
      userId:    user.uid,
    );
    final dto = ProductDTO.fromDomain(updated);

    // 3) escribe EXACTAMENTE en doc(id) para no duplicar:
    await FirebaseFirestore.instance
        .collection('products')   // o tu ruta real
        .doc(id)
        .set(dto.toFirestore());
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
