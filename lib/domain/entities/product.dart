/// Domain entity that represents a product in the app.
/// This model should be independent from Firebase or external sources.
class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final List<String> imageUrls;
  final String sellerName;

  final List<String> favoritedBy;
  final DateTime? timestamp;
  final String userId;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrls,
    required this.sellerName,
    required this.favoritedBy,
    this.timestamp,
    required this.userId,

  });

  /// Creates a copy of the product with optional field overrides.
  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? price,
    List<String>? imageUrls,
    String? sellerName,
    List<String>? favoritedBy,
    DateTime? timestamp,
    String? userId,
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
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
    );
  }

  /// Equality override to compare by value.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Product &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              description == other.description &&
              category == other.category &&
              price == other.price &&
              imageUrls.toString() == other.imageUrls.toString() &&
              sellerName == other.sellerName &&
              favoritedBy.toString() == other.favoritedBy.toString() &&
              timestamp == other.timestamp &&
              userId == other.userId;

  /// Custom hashCode to support equality.
  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      category.hashCode ^
      price.hashCode ^
      imageUrls.hashCode ^
      sellerName.hashCode ^
      favoritedBy.hashCode ^
      timestamp.hashCode ^
      userId.hashCode;
}
