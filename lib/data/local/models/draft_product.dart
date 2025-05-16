import 'package:hive/hive.dart';
import 'package:senemarket/domain/entities/product.dart';

part 'draft_product.g.dart';

@HiveType(typeId: 3)
class DraftProduct extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) String description;
  @HiveField(3) double price;
  @HiveField(4) String category;
  @HiveField(5) String userId;
  @HiveField(6) DateTime createdAt;
  @HiveField(7) List<String> imagePaths;
  @HiveField(8) DateTime lastUpdated;
  @HiveField(9) bool isComplete;  // Indica si el draft tiene todos los campos requeridos

  DraftProduct({
    required this.id,
    this.name = '',
    this.description = '',
    this.price = 0.0,
    this.category = '',
    required this.userId,
    DateTime? createdAt,
    List<String>? imagePaths,
    DateTime? lastUpdated,
    this.isComplete = false,
  })  : createdAt   = createdAt   ?? DateTime.now(),
        imagePaths  = imagePaths  ?? [],
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Convierte este borrador en un Product listo para publicar.
  Product toProduct(List<String> imagePaths) {
    return Product(
      id: id,
      name: name,
      description: description,
      category: category,
      price: price,
      imageUrls: imagePaths,
      sellerName: '',        // se rellenará en repositorio
      favoritedBy: [],       // vacío por defecto
      timestamp: lastUpdated,
      userId: userId,
    );
  }

  /// Verifica si el draft está completo
  bool get isValid => 
    name.isNotEmpty && 
    description.isNotEmpty && 
    price > 0 && 
    category.isNotEmpty && 
    imagePaths.isNotEmpty;

  /// Actualiza el estado de completitud
  void updateCompleteness() {
    isComplete = isValid;
  }
}
