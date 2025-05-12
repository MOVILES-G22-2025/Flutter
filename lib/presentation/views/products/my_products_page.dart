import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:senemarket/constants.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/product_repository.dart'; // ← Usa la abstracción

import 'package:senemarket/presentation/views/products/viewmodel/edit_product_viewmodel.dart';
import 'package:senemarket/presentation/views/products/edit_product_page.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import 'package:senemarket/presentation/views/products/widgets/my_product_card.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_search_viewmodel.dart';
import 'package:senemarket/presentation/widgets/global/search_bar.dart' as searchBar;

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({Key? key}) : super(key: key);

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  final _auth = FirebaseAuth.instance;
  late final ProductRepository _productRepo;
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    _productRepo = context.read<ProductRepository>(); // ← Aquí se usa la abstracción

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductSearchViewModel>().updateSearchQuery('');
    });
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Delete product",
          style: TextStyle(
            fontFamily: 'Cabin',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: const Text(
          "Are you sure you want to delete this product?",
          style: TextStyle(
            fontFamily: 'Cabin',
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(
                fontFamily: 'Cabin',
                color: Colors.grey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(
                fontFamily: 'Cabin',
                color: AppColors.primary30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _productRepo.deleteProduct(productId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final searchVM = context.watch<ProductSearchViewModel>();
    final searchQuery = searchVM.searchQuery.trim();

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary0),
        centerTitle: true,
        title: const Text(
          'My products',
          style: TextStyle(
            fontFamily: 'Cabin',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary0,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Not logged in"))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: searchBar.SearchBar(
              hintText: 'Search your products...',
              onChanged: searchVM.updateSearchQuery,
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.only(top: 4.0, left: 16.0, right: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Press and hold a product to view options',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Cabin',
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productRepo.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allProducts = snapshot.data ?? [];
                final myProducts = allProducts.where((p) => p.userId == user.uid).toList();

                final displayedProducts = searchQuery.isEmpty
                    ? myProducts
                    : myProducts.where((p) {
                  final q = searchQuery.toLowerCase();
                  return p.name.toLowerCase().contains(q) ||
                      p.description.toLowerCase().contains(q);
                }).toList();

                if (displayedProducts.isEmpty) {
                  return const Center(child: Text("No products found", style: TextStyle(
                    fontFamily: 'Cabin',
                    fontSize: 18,
                    color: Colors.grey,
                  ),));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayedProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final product = displayedProducts[index];
                    return MyProductCard(
                      product: product,
                      onDelete: () => _deleteProduct(product.id),
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) => EditProductViewModel(context.read()),
                            child: EditProductPage(product: product),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBarApp(selectedIndex: _selectedIndex),
    );
  }
}
