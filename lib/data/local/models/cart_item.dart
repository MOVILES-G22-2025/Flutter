import 'package:hive/hive.dart';
part 'cart_item.g.dart';

@HiveType(typeId: 8)
class CartItem extends HiveObject {
  @HiveField(0)
  String productId;
  @HiveField(1)
  String name;
  @HiveField(2)
  double price;
  @HiveField(3)
  int quantity;
  @HiveField(4)
  String imageUrl;
  @HiveField(5)
  String? description;
  @HiveField(6)
  String? category;
  @HiveField(7)
  String sellerName;
  @HiveField(8)
  String? userId;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.sellerName,
    required this.userId,
  });
}
