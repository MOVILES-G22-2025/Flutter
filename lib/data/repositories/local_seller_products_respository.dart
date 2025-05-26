import 'package:hive/hive.dart';
import 'package:senemarket/domain/entities/product.dart';

class LocalSellerProductsRepository {
  Future<Box<Product>> openBox(String sellerId) async {
    return await Hive.openBox<Product>('products_$sellerId');
  }

  Future<void> saveProducts(String sellerId, List<Product> products) async {
    final box = await openBox(sellerId);
    await box.clear();
    await box.addAll(products);
  }

  Future<List<Product>> getProducts(String sellerId) async {
    final box = await openBox(sellerId);
    return box.values.toList();
  }
}
