import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/connectivity_service.dart';
import '../local/database/database_helper.dart';
import '../local/operation_queue.dart';
import '../local/models/operation.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/entities/product.dart';
import '../models/product_dto.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FirebaseFirestore _firestore;
  final ConnectivityService _connectivity;
  final DatabaseHelper _dbHelper;
  final OperationQueue _queue;
  final String _seed = const Uuid().v4();

  FavoritesRepositoryImpl({
    FirebaseFirestore? firestore,
    ConnectivityService? connectivityService,
    DatabaseHelper? databaseHelper,
    OperationQueue? operationQueue,

  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivityService ?? ConnectivityService(),
        _dbHelper = databaseHelper ?? DatabaseHelper(),
        _queue = operationQueue ?? OperationQueue();

  /// 1) Carga offline/online
  Future<List<Product>> fetchFavorites({
    required String userId,
    bool forceRemote = false,
  }) async {
    final online = await _connectivity.isOnline$.first;
    if (online || forceRemote) {
      // ONLINE: leo Firestore y actualizo cache
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final favIds = List<String>.from(userDoc.data()?['favorites'] ?? []);
      final products = <Product>[];

      for (final id in favIds) {
        final doc = await _firestore.collection('products').doc(id).get();
        if (!doc.exists) continue;
        final dto = ProductDTO.fromFirestore(doc.id, doc.data()!);
        final p = dto.toDomain();
        products.add(p);

        // Upsert en cache local
        await _dbHelper.upsertCachedProduct({
          'id':           doc.id,
          'name':         dto.name,
          'description':  dto.description,
          'category':     dto.category,
          'price':        dto.price,
          'sellerName':   dto.sellerName,
          'imageUrls':    dto.imageUrls.join(','),
          'favoritedBy':  jsonEncode(dto.favoritedBy),
          'timestamp':    p.timestamp?.millisecondsSinceEpoch,
          'userId':       p.userId,
        });
      }
      return products;
    } else {
      // OFFLINE: leo sólo favoritos de la cache
      final rows = await _dbHelper.getCachedFavorites(userId);
      return rows.map((row) {
        final favList = (jsonDecode(row['favoritedBy'] as String) as List).cast<String>();
        final urls = (row['imageUrls'] as String).split(',');
        final tsInt = row['timestamp'] as int?;
        final ts = tsInt != null ? DateTime.fromMillisecondsSinceEpoch(tsInt) : null;
        return Product(
          id:          row['id'] as String,
          name:        row['name'] as String,
          description: row['description'] as String,
          category:    row['category'] as String,
          price:       row['price'] as double,
          imageUrls:   urls,
          sellerName:  row['sellerName'] as String,
          favoritedBy: favList,
          timestamp:   ts,
          userId:      row['userId'] as String,
        );
      }).toList();
    }
  }

  @override
  ConnectivityService get connectivity => _connectivity;

  /// 2) Marca favorito (cache + Firestore o cola)
  @override
  Future<void> addProductToFavorites(String userId, String productId) async {
    await _updateLocalFavoritedBy(productId, userId, add: true);
    final online = await _connectivity.isOnline$.first;
    if (online) {
      await Future.wait([
        _firestore.collection('users').doc(userId).set({
          'favorites': FieldValue.arrayUnion([productId])
        }, SetOptions(merge: true)),
        _firestore.collection('products').doc(productId).set({
          'favoritedBy': FieldValue.arrayUnion([userId])
        }, SetOptions(merge: true)),
      ]);
    } else {
      await _queue.enqueue(Operation(
        id: 'fav_add_${_seed}_${DateTime.now().millisecondsSinceEpoch}',
        type: OperationType.toggleFavorite,
        payload: {'action':'add','userId':userId,'productId':productId},
      ));
    }
  }

  /// 3) Desmarca favorito
  @override
  Future<void> removeProductFromFavorites(String userId, String productId) async {
    await _updateLocalFavoritedBy(productId, userId, add: false);
    final online = await _connectivity.isOnline$.first;
    if (online) {
      await Future.wait([
        _firestore.collection('users').doc(userId).set({
          'favorites': FieldValue.arrayRemove([productId])
        }, SetOptions(merge: true)),
        _firestore.collection('products').doc(productId).set({
          'favoritedBy': FieldValue.arrayRemove([userId])
        }, SetOptions(merge: true)),
      ]);
    } else {
      await _queue.enqueue(Operation(
        id: 'fav_rem_${_seed}_${DateTime.now().millisecondsSinceEpoch}',
        type: OperationType.toggleFavorite,
        payload: {'action':'remove','userId':userId,'productId':productId},
      ));
    }
  }

  /// Actualiza sólo el campo `favoritedBy` en la tabla `cached_products`
  Future<void> _updateLocalFavoritedBy(
      String productId, String userId,
      { required bool add }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'cached_products',
      columns: ['favoritedBy'],
      where: 'id = ?',
      whereArgs: [productId],
    );
    if (rows.isEmpty) return;

    final currentJson = rows.first['favoritedBy'] as String;
    final list = (jsonDecode(currentJson) as List).cast<String>();
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
}
