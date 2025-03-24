import 'package:firebase_auth/firebase_auth.dart';
import 'package:algolia/algolia.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_dto.dart';
import '../datasources/product_remote_data_source.dart';

/// Implements the ProductRepository interface.
/// Connects domain logic with Firebase and Algolia services.
class ProductRepositoryImpl implements ProductRepository {
  final FirebaseAuth _auth;
  final ProductRemoteDataSource _remoteDataSource;
  final Algolia _algolia;

  ProductRepositoryImpl({
    FirebaseAuth? auth,
    ProductRemoteDataSource? remoteDataSource,
    Algolia? algolia,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _remoteDataSource = remoteDataSource ?? ProductRemoteDataSource(),
        _algolia = algolia ??
            Algolia.init(
              applicationId: 'AAJ6U9G25X',
              apiKey: 'e1450d2b94d56f3a2bf7a7978f255be1',
            );

  /// Uses Algolia to search products by keyword.
  @override
  Future<List<Product>> searchProducts(String query) async {
    final snapshot =
    await _algolia.instance.index('senemarket_products_index').query(query).getObjects();
    return snapshot.hits
        .map((hit) => ProductDTO.fromAlgoliaHit(hit).toDomain())
        .toList();
  }

  /// Adds a new product to Firestore with uploaded images and seller info.
  @override
  Future<void> addProduct({
    required List<XFile?> images,
    required Product product,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final imageUrls = await _remoteDataSource.uploadImages(images);
    if (imageUrls.isEmpty) throw Exception("No images uploaded");

    final sellerName = await _remoteDataSource.getSellerName(user.uid);
    final updatedProduct = product.copyWith(imageUrls: imageUrls, sellerName: sellerName, userId: user.uid);
    final dto = ProductDTO.fromDomain(updatedProduct);

    await _remoteDataSource.saveProduct(user.uid, dto);
  }

  /// Returns a real-time stream of product list from Firestore.
  @override
  Stream<List<Product>> getProductsStream() {
    return _remoteDataSource.getProductDTOStream().map(
          (dtoList) => dtoList.map((dto) => dto.toDomain()).toList(),
    );
  }

  /// Adds a user ID to the favoritedBy list of a product.
  @override
  Future<void> addProductFavorite({required String userId, required String productId}) {
    return _remoteDataSource.updateFavorites(productId, userId, true);
  }

  /// Removes a user ID from the favoritedBy list of a product.
  @override
  Future<void> removeProductFavorite({required String userId, required String productId}) {
    return _remoteDataSource.updateFavorites(productId, userId, false);
  }
}
