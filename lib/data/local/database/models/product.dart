// lib/data/models/product.dart
class Product {
  final int? id;                      // ← sin cambios (usa tu clave primaria local)
  final String category;
  final String description;
  final List<String> imageUrls;
  final String name;
  final double price;
  final String sellerName;

  /// Milisegundos desde 1970-01-01 00:00:00 UTC
  final int timestamp;                // ← antes era String
  final String userId;

  Product({
    this.id,
    required this.category,
    required this.description,
    required this.imageUrls,
    required this.name,
    required this.price,
    required this.sellerName,
    required this.timestamp,          // ahora es `int`
    required this.userId,
  });

  // ---------- SQLite helpers ----------

  Map<String, dynamic> toMap() {
    return {
      'id'        : id,
      'category'  : category,
      'description': description,
      'imageUrls' : imageUrls.join(','),   // lista → String
      'name'      : name,
      'price'     : price,
      'sellerName': sellerName,
      'timestamp' : timestamp,             // int → int
      'userId'    : userId,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id          : map['id'],
      category    : map['category'],
      description : map['description'],
      imageUrls   : (map['imageUrls'] as String).split(','), // String → lista
      name        : map['name'],
      price       : map['price'],
      sellerName  : map['sellerName'],
      timestamp   : map['timestamp'],       // int ← int
      userId      : map['userId'],
    );
  }
}
