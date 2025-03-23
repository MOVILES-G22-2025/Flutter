import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:algolia/algolia.dart';

/// Data Transfer Object (DTO) to manage product data
/// between Firestore, Algolia and domain layers.
class ProductDTO {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final List<String> imageUrls;
  final String sellerName;
  final List<String> favoritedBy;
  final DateTime? timestamp;

  const ProductDTO({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrls,
    required this.sellerName,
    required this.favoritedBy,
    this.timestamp,
  });

  // -----------------------------
  // Firebase → DTO
  // -----------------------------
  /// Builds a ProductDTO from Firestore data.
  factory ProductDTO.fromFirestore(String docId, Map<String, dynamic> map) {
    return ProductDTO(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: _parseDouble(map['price']),
      imageUrls: _toStringList(map['imageUrls']),
      sellerName: map['sellerName'] ?? '',
      favoritedBy: _toStringList(map['favoritedBy']),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts ProductDTO to Firestore map for saving.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imageUrls': imageUrls,
      'sellerName': sellerName,
      'favoritedBy': favoritedBy,
    };
  }

  // -----------------------------
  // Algolia → DTO
  // -----------------------------
  /// Converts a search result from Algolia into ProductDTO.
  factory ProductDTO.fromAlgoliaHit(AlgoliaObjectSnapshot hit) {
    final map = Map<String, dynamic>.from(hit.data);
    return ProductDTO(
      id: hit.objectID,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      price: _parseDouble(map['price']),
      imageUrls: _toStringList(map['imageUrls']),
      sellerName: map['sellerName'] ?? '',
      favoritedBy: _toStringList(map['favoritedBy']),
    );
  }

  // -----------------------------
  // Domain ↔ DTO
  // -----------------------------
  /// Converts DTO to domain Product entity.
  Product toDomain() {
    return Product(
      id: id,
      name: name,
      description: description,
      category: category,
      price: price,
      imageUrls: imageUrls,
      sellerName: sellerName,
      favoritedBy: favoritedBy,
      timestamp: timestamp,
    );
  }

  /// Converts domain Product entity to DTO.
  static ProductDTO fromDomain(Product product) {
    return ProductDTO(
      id: product.id,
      name: product.name,
      description: product.description,
      category: product.category,
      price: product.price,
      imageUrls: product.imageUrls,
      sellerName: product.sellerName,
      favoritedBy: product.favoritedBy,
    );
  }

  // -----------------------------
  // Helpers
  // -----------------------------

  /// Tries to convert any input into double.
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Ensures the field is a list of strings.
  static List<String> _toStringList(dynamic val) {
    if (val == null) return [];
    if (val is List) {
      return val.whereType<String>().toList();
    }
    return [];
  }

  /// Alternative way to build from DocumentSnapshot (used in streams).
  factory ProductDTO.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductDTO(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      price: double.tryParse(data['price'].toString()) ?? 0.0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      sellerName: data['sellerName'] ?? '',
      favoritedBy: [],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
