import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:senemarket/constants.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';
import 'package:senemarket/presentation/views/products/viewmodel/edit_product_viewmodel.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import 'package:senemarket/presentation/views/products/widgets/my_product_card.dart';
import 'package:senemarket/presentation/views/products/edit_product_page.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({Key? key}) : super(key: key);

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  final _auth = FirebaseAuth.instance;
  final _productRepo = ProductRepositoryImpl();

  int _selectedIndex = 4;

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
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

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary0),
        centerTitle: true,
        title: const Text(
          'My Products',
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
          : StreamBuilder<List<Product>>(
        stream: _productRepo.getProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProducts = snapshot.data ?? [];
          final myProducts = allProducts
              .where((p) => p.userId == user.uid)
              .toList();

          if (myProducts.isEmpty) {
            return const Center(
              child: Text("You haven’t added any products yet."),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two products per row
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75, // Adjust height/width ratio
            ),
            itemBuilder: (context, index) {
              final product = myProducts[index];
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
      bottomNavigationBar: NavigationBarApp(selectedIndex: _selectedIndex),
    );
  }
}
