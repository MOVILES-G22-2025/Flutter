import 'package:algolia/algolia.dart';

class ProductSearchRepository {
  // Configura tu instancia de Algolia con tus credenciales.
  static final Algolia algolia = Algolia.init(
    applicationId: 'AAJ6U9G25X', // Reemplaza por tu Application ID
    apiKey: 'e1450d2b94d56f3a2bf7a7978f255be1', // Reemplaza por tu API Key de búsqueda
  );

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final AlgoliaQuery algoliaQuery = algolia.instance.index('senemarket_products_index').query(query);
    final AlgoliaQuerySnapshot snapshot = await algoliaQuery.getObjects();
    return snapshot.hits.map((hit) {
      final data = Map<String, dynamic>.from(hit.data);
      data['id'] = hit.objectID; // Asigna el objectID de Algolia al campo 'id'

      return data;
    }).toList();
  }



}
