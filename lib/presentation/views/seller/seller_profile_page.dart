import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/presentation/views/products/widgets/product_card.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:senemarket/data/local/models/cached_user.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';

class SellerProfilePage extends StatefulWidget {
  final String userId;
  const SellerProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _SellerProfilePageState createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final _productRepo = ProductRepositoryImpl();
  List<Product>? _products;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final online = await _productRepo.connectivity.isOnline$.first;
    if (online) {
      _productRepo.getProductsStream().listen((products) {
        final sellerProducts = products.where((p) => p.userId == widget.userId).toList();
        setState(() {
          _products = sellerProducts;
          _isLoading = false;
        });
      });
    } else {
      final cachedProducts = await _productRepo.getCachedProducts();
      final sellerProducts = cachedProducts.where((p) => p.userId == widget.userId).toList();
      setState(() {
        _products = sellerProducts;
        _isLoading = false;
      });
    }
  }

  Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<Map<String, dynamic>?> fetchSellerInfoAndCache() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    final data = doc.data();
    if (data != null) {
      final box = await Hive.openBox<CachedUser>('cached_users');
      final cachedUser = CachedUser(
        id: widget.userId,
        name: data['name'] ?? '',
        career: data['career'] ?? '',
        semester: data['semester']?.toString() ?? '',
        photoUrl: data['photoUrl'] ?? '',
      );
      await box.put(widget.userId, cachedUser);
    }
    return data;
  }

  Future<CachedUser?> fetchSellerInfoOffline() async {
    final box = await Hive.openBox<CachedUser>('cached_users');
    return box.get(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = FirebaseAuth.instance.currentUser?.uid;
    final navIndex = (widget.userId == myUserId) ? 4 : 0;

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
      body: FutureBuilder<bool>(
        future: isOnline(),
        builder: (context, snapshotOnline) {
          final isConnected = snapshotOnline.data ?? true;

          if (isConnected) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: fetchSellerInfoAndCache(),
              builder: (context, snapshotUser) {
                if (!snapshotUser.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final seller = snapshotUser.data!;
                return _buildProfileContent(
                  name: seller['name'] ?? '',
                  career: seller['career'] ?? '',
                  semester: seller['semester']?.toString() ?? '',
                  photoUrl: seller['photoUrl'] ?? '',
                  offline: false,
                  navIndex: navIndex,
                );
              },
            );
          } else {
            return FutureBuilder<CachedUser?>(
              future: fetchSellerInfoOffline(),
              builder: (context, snapshotOffline) {
                if (!snapshotOffline.hasData) {
                  return const Center(child: Text("No se encontró el usuario offline"));
                }
                final localUser = snapshotOffline.data!;
                return _buildProfileContent(
                  name: localUser.name,
                  career: localUser.career,
                  semester: localUser.semester,
                  photoUrl: localUser.photoUrl,
                  offline: true,
                  navIndex: navIndex,
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: NavigationBarApp(selectedIndex: navIndex),
    );
  }

  Widget _buildProfileContent({
    required String name,
    required String career,
    required String semester,
    required String photoUrl,
    required bool offline,
    required int navIndex,
  }) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 24),
        if (offline)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Center(

            ),
          ),
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
            '$career | Semestre $semester',
            style: const TextStyle(
              fontFamily: 'Cabin',
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_products == null || _products!.isEmpty)
              ? const Center(child: Text("No products found"))
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.70,
            ),
            itemCount: _products!.length,
            itemBuilder: (context, index) {
              return ProductCard(
                product: _products![index],
                onProductTap: () {},
                originIndex: navIndex,
              );
            },
          ),
        ),
      ],
    );
  }
}
