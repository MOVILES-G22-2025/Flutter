class Producto {
  final int? id;
  final String category;
  final String description;
  final List<String> imageUrls;    // Lista de URLs de imágenes
  final String name;
  final double price;
  final String sellerName;
  final String timestamp;
  final String userId;

  Producto({
    this.id,
    required this.category,
    required this.description,
    required this.imageUrls,
    required this.name,
    required this.price,
    required this.sellerName,
    required this.timestamp,
    required this.userId,
  });

  // Convierte un producto a Map para insertar en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'imageUrls': imageUrls.join(','),  // Convertir lista a String
      'name': name,
      'price': price,
      'sellerName': sellerName,
      'timestamp': timestamp,
      'userId': userId,
    };
  }

  // Convierte un Map de la base de datos a un Producto
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      category: map['category'],
      description: map['description'],
      imageUrls: (map['imageUrls'] as String).split(','),  // Convertir String a lista
      name: map['name'],
      price: map['price'],
      sellerName: map['sellerName'],
      timestamp: map['timestamp'],
      userId: map['userId'],
    );
  }
}
