import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/views/products/widgets/product_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';

class SellerProfilePage extends StatelessWidget {
  final String userId;
  const SellerProfilePage({Key? key, required this.userId}) : super(key: key);

  Future<Map<String, dynamic>?> fetchSellerInfo() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchSellerProducts() async {
    final query = await FirebaseFirestore.instance
        .collection('products')
        .where('userId', isEqualTo: userId)
        .get();
    return query.docs;
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = FirebaseAuth.instance.currentUser?.uid;
    final navIndex = (userId == myUserId) ? 4 : 0;

    return Scaffold(
      backgroundColor: AppColors.primary40,
      appBar: AppBar(
        backgroundColor: AppColors.primary40,
        elevation: 0,
        title: const Text(
          'Seller Profile',
          style: TextStyle(
            fontFamily: 'Cabin',
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
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
          final semester = seller['semester']?.toString() ?? '';
          final photoUrl = seller['photoUrl'] ?? '';

          return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            future: fetchSellerProducts(),
            builder: (context, prodSnapshot) {
              if (prodSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!prodSnapshot.hasData || prodSnapshot.data!.isEmpty) {
                return const Center(child: Text("No products found for this seller"));
              }
              final products = prodSnapshot.data!;
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 24),
                  // Avatar, nombre, carrera y semestre
                  Center(
                    child: photoUrl.isNotEmpty
                        ? CircleAvatar(
                      radius: 46,
                      backgroundImage: CachedNetworkImageProvider(photoUrl),
                    )
                        : const CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Cabin',
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '$career | Semester $semester',
                      style: const TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Contenedor con grid de productos (dentro del ListView)
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 24.0, left: 10, right: 10, bottom: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.70,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final doc = products[index];
                        final data = doc.data();
                        final productId = doc.id;

                        final product = Product(
                          id: productId,
                          name: data['name'] ?? '',
                          description: data['description'] ?? '',
                          category: data['category'] ?? '',
                          price: (data['price'] is int)
                              ? (data['price'] as int).toDouble()
                              : (data['price'] ?? 0).toDouble(),
                          imageUrls: List<String>.from(data['imageUrls'] ?? []),
                          sellerName: data['sellerName'] ?? '',
                          favoritedBy: data['favoritedBy'] != null
                              ? List<String>.from(data['favoritedBy'])
                              : <String>[],
                          timestamp: data['timestamp'] != null
                              ? (data['timestamp'] is DateTime
                              ? data['timestamp']
                              : (data['timestamp'] as Timestamp).toDate())
                              : null,
                          userId: data['userId'] ?? '',
                        );

                        return ProductCard(
                          product: product,
                          onProductTap: () {},
                          originIndex: navIndex,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBarApp(selectedIndex: navIndex),
    );
  }
}

