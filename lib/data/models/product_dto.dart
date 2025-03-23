// lib/data/models/product_dto.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:algolia/algolia.dart';

class ProductDTO {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final List<String> imageUrls;
  final String sellerName;
  final List<String> favoritedBy;

  const ProductDTO({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrls,
    required this.sellerName,
    required this.favoritedBy,
  });

  // -----------------------------
  // Firebase ↔ DTO
  // -----------------------------
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
    );
  }

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
  // Algolia ↔ DTO
  // -----------------------------
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
  // Dominio ↔ DTO
  // -----------------------------
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
    );
  }

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
  // Auxiliares
  // -----------------------------
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static List<String> _toStringList(dynamic val) {
    if (val == null) return [];
    if (val is List) {
      return val.whereType<String>().toList();
    }
    return [];
  }

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
    );
  }

}
