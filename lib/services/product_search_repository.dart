import 'package:algolia/algolia.dart';

class ProductSearchRepository {
  // Configura tu instancia de Algolia con tus credenciales.
  static final Algolia algolia = Algolia.init(
    applicationId: 'R93QX2D4XM', // Reemplaza por tu Application ID
    apiKey: 'cb8807b005fd94e25562c67ffee2b231', // Reemplaza por tu API Key de búsqueda
  );

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final AlgoliaQuery algoliaQuery = algolia.instance.index('products_senemarket_index').query(query);
    final AlgoliaQuerySnapshot snapshot = await algoliaQuery.getObjects();
    return snapshot.hits.map((hit) {
      final data = Map<String, dynamic>.from(hit.data);
      data['id'] = hit.objectID; // Asigna el objectID de Algolia al campo 'id'

      return data;
    }).toList();
  }


}
