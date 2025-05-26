import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Si tienes tus modelos en archivos separados, impórtalos aquí.
// import '../../models/usuario_model.dart';
// import '../../models/producto_model.dart';

class SellerProfilePage extends StatelessWidget {
  final String userId;
  const SellerProfilePage({Key? key, required this.userId}) : super(key: key);

  // Consulta Firestore para el usuario (vendedor)
  Future<Map<String, dynamic>?> fetchSellerInfo() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  // Consulta Firestore para los productos de este vendedor
  Future<List<Map<String, dynamic>>> fetchSellerProducts() async {
    final query = await FirebaseFirestore.instance
        .collection('products')
        .where('userId', isEqualTo: userId)
        .get();
    return query.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Profile'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchSellerInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Seller not found"));
          }
          final seller = snapshot.data!;
          final name = seller['name'] ?? '';
          final career = seller['career'] ?? '';
          final semester = seller['semester'] ?? '';
          final photoUrl = seller['photoUrl'] ?? '';

          return Column(
            children: [
              const SizedBox(height: 24),
              // Foto o avatar anónimo
              photoUrl.isNotEmpty
                  ? CircleAvatar(
                radius: 48,
                backgroundImage: CachedNetworkImageProvider(photoUrl),
              )
                  : const CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                "$career | Semestre $semester",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Productos publicados por el vendedor
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchSellerProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No products found for this seller"));
                    }
                    final products = snapshot.data!;
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final imageUrl = (product['imageUrls'] != null && product['imageUrls'].isNotEmpty)
                            ? product['imageUrls'][0]
                            : '';
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                                    : Container(
                                  height: 120,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 48, color: Colors.white),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "\$${product['price'] ?? ''}",
                                      style: const TextStyle(color: Colors.green, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
