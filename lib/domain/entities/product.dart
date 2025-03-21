// lib/domain/entities/product.dart

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final List<String> imageUrls;
  final String sellerName;
  final List<String> favoritedBy;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrls,
    required this.sellerName,
    required this.favoritedBy,
  });

  // Ejemplo de copyWith si deseas modificar campos
  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    List<String>? imageUrls,
    String? sellerName,
    List<String>? favoritedBy,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerName: sellerName ?? this.sellerName,
      favoritedBy: favoritedBy ?? this.favoritedBy,
    );
  }
}
