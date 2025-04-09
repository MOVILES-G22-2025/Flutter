import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/presentation/views/products/viewmodel/product_search_viewmodel.dart';

import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import 'package:senemarket/presentation/widgets/global/search_bar.dart' as searchBar;
import 'package:senemarket/presentation/widgets/global/filter_bar.dart';
import 'package:senemarket/presentation/views/products/widgets/product_card.dart';

import 'package:senemarket/constants.dart' as constants;
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/data/repositories/product_repository_impl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Parámetros de orden: "Newest first" o "Oldest first"
  String _sortOrder = 'Newest first';
  // Orden por precio: "Price: Low to High" o "Price: High to Low"
  String? _sortPrice;

  // Categorías seleccionadas manualmente
  List<String> _selectedCategories = [];

  // Conteo de clics en categorías (para ordenar en la FilterBar)
  Map<String, int> _categoryClicks = {};

  // Indica si se activó el Academic Calendar en la UI
  bool _academicCalendarActive = false;

  // Categoría destacada obtenida de la DB según la fecha actual
  String? _featuredCategory;

  // Usuario autenticado
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  // Repositorio de productos
  final _productRepo = ProductRepositoryImpl();

  @override
  void initState() {
    super.initState();
    // Imprime la hora del dispositivo (local y UTC)
    final nowLocal = DateTime.now();
    final nowUtc = nowLocal.toUtc();
    debugPrint("[HomePage] initState -> Device local time: $nowLocal, Device UTC time: $nowUtc");

    // Reinicia el query de búsqueda
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchVM = context.read<ProductSearchViewModel>();
      searchVM.updateSearchQuery('');
      debugPrint("[HomePage] initState -> PostFrame: Busqueda reseteada");
    });

    _loadUserClicks();
    _loadFeaturedCategory();
  }

  /// Carga los clics en categorías almacenados en el documento del usuario
  Future<void> _loadUserClicks() async {
    debugPrint("[HomePage] _loadUserClicks -> Iniciando lectura de doc del usuario");
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      setState(() {
        _categoryClicks = Map<String, int>.from(data?['categoryClicks'] ?? {});
      });
      debugPrint("[HomePage] _loadUserClicks -> Cargados: $_categoryClicks");
    } else {
      debugPrint("[HomePage] _loadUserClicks -> No existe doc para el usuario");
    }
  }

  /// Consulta Firestore (colección 'featured_categories') para ver si hay un doc
  /// cuyo rango de fechas incluya la fecha actual.
  Future<void> _loadFeaturedCategory() async {
    try {
      final nowLocal = DateTime.now();
      final nowUtc = nowLocal.toUtc();
      debugPrint("[HomePage] _loadFeaturedCategory -> nowLocal: $nowLocal, nowUtc: $nowUtc");

      // Usamos la fecha local (suponiendo que Firestore guardó Timestamps correctos)
      final nowTs = Timestamp.fromDate(nowLocal);
      debugPrint("[HomePage] _loadFeaturedCategory -> nowTs: ${nowTs.toDate()}");

      final snapshot = await FirebaseFirestore.instance
          .collection('featured_categories')
          .where('startDate', isLessThanOrEqualTo: nowTs)
          .where('endDate', isGreaterThanOrEqualTo: nowTs)
          .get();

      debugPrint("[HomePage] _loadFeaturedCategory -> docs encontrados: ${snapshot.docs.length}");

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final docId = doc.id;
        debugPrint("[HomePage] _loadFeaturedCategory -> primer doc encontrado (ID: $docId): $data");
        final cat = data['category'] as String?;
        if (cat != null) {
          setState(() {
            _featuredCategory = cat;
          });
          debugPrint("[HomePage] _loadFeaturedCategory -> _featuredCategory asignada: $_featuredCategory");
        } else {
          debugPrint("[HomePage] _loadFeaturedCategory -> El documento no contiene el campo 'category'");
        }
      } else {
        debugPrint("[HomePage] _loadFeaturedCategory -> No se encontraron documentos válidos para la fecha actual");
      }
    } catch (e) {
      debugPrint("[HomePage] _loadFeaturedCategory -> Error: $e");
    }
  }

  /// Maneja el tap en la barra de navegación inferior
  void _onItemTapped(int index) {
    debugPrint("[HomePage] _onItemTapped -> index: $index");
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/chats');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/add_product');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/favorites');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  /// Incrementa el contador de clics en una categoría y actualiza Firestore
  void _incrementCategoryClick(String category) async {
    debugPrint("[HomePage] _incrementCategoryClick -> category: $category");
    setState(() {
      _categoryClicks[category] = (_categoryClicks[category] ?? 0) + 1;
    });
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.set({
      'categoryClicks': {category: FieldValue.increment(1)}
    }, SetOptions(merge: true));
    debugPrint("[HomePage] _incrementCategoryClick -> Actualizado en Firestore");
  }

  /// Registra un clic en un producto (lo guarda en la colección 'product-clics')
  Future<void> _registerProductClick(Product product) async {
    debugPrint("[HomePage] _registerProductClick -> product.id: ${product.id}");
    try {
      await FirebaseFirestore.instance.collection('product-clics').add({
        'userId': userId,
        'productId': product.id,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint("[HomePage] _registerProductClick -> Clic registrado");
    } catch (e) {
      debugPrint("[HomePage] _registerProductClick -> Error: $e");
    }
  }

  /// Retorna una lista de categorías ordenadas según la cantidad de clics
  List<String> get _categoriesSortedByClicks {
    final allCategories = constants.ProductClassification.categories;
    final sortedList = allCategories.toList()
      ..sort((a, b) {
        final clicksA = _categoryClicks[a] ?? 0;
        final clicksB = _categoryClicks[b] ?? 0;
        return clicksB.compareTo(clicksA);
      });
    return sortedList;
  }

  /// Filtra y ordena la lista de productos.
  /// Primero se filtra por búsqueda y categorías seleccionadas.
  /// Luego se ordena por fecha o precio y, si está activo Academic Calendar,
  /// se reordena para poner los productos de la categoría destacada al principio.
  List<Product> _filterProducts(
      List<Product> baseProducts,
      ProductSearchViewModel searchViewModel,
      ) {
    debugPrint("[HomePage] _filterProducts -> INICIO");
    final searchQuery = searchViewModel.searchQuery;
    debugPrint("[HomePage] _filterProducts -> searchQuery: $searchQuery");

    // Si hay query, utilizar los resultados de Algolia; de lo contrario, usar los productos base.
    final List<Product> products = searchQuery.isNotEmpty
        ? searchViewModel.searchResults
        : baseProducts;
    debugPrint("[HomePage] _filterProducts -> products.length: ${products.length}");

    // Excluir los productos creados por el usuario actual
    final visibleProducts = products.where((p) => p.userId != userId).toList();
    debugPrint("[HomePage] _filterProducts -> visibleProducts.length: ${visibleProducts.length}");

    // Filtrar por las categorías seleccionadas manualmente desde la UI
    List<Product> filtered = _selectedCategories.isEmpty
        ? visibleProducts
        : visibleProducts.where((product) {
      final productCategory = product.category.toLowerCase();
      return _selectedCategories.any((selected) =>
          productCategory.contains(selected.toLowerCase()));
    }).toList();
    debugPrint("[HomePage] _filterProducts -> filtered.length tras selectedCategories: ${filtered.length}");

    // Ordenar por fecha
    filtered.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return 1;
      if (b.timestamp == null) return -1;
      return _sortOrder == 'Newest first'
          ? b.timestamp!.compareTo(a.timestamp!)
          : a.timestamp!.compareTo(b.timestamp!);
    });
    debugPrint("[HomePage] _filterProducts -> Ordenado por fecha, _sortOrder=$_sortOrder");

    // Ordenar por precio si se seleccionó esa opción
    if (_sortPrice != null) {
      filtered.sort((a, b) {
        return _sortPrice == 'Price: Low to High'
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price);
      });
      debugPrint("[HomePage] _filterProducts -> Ordenado por precio, _sortPrice=$_sortPrice");
    }

    // Si Academic Calendar está activo y se obtuvo la categoría destacada, reordenar para poner esos productos primero.
    debugPrint("[HomePage] _filterProducts -> _academicCalendarActive=$_academicCalendarActive, _featuredCategory=$_featuredCategory");
    if (_academicCalendarActive && _featuredCategory != null) {
      final fcLower = _featuredCategory!.toLowerCase();
      filtered.sort((a, b) {
        final aIsFeatured = a.category.toLowerCase() == fcLower;
        final bIsFeatured = b.category.toLowerCase() == fcLower;
        if (aIsFeatured && !bIsFeatured) return -1;
        if (!aIsFeatured && bIsFeatured) return 1;
        return 0;
      });
      debugPrint("[HomePage] _filterProducts -> Reordenados con featuredCategory=$_featuredCategory");
    }

    debugPrint("[HomePage] _filterProducts -> FIN, filtered.length=${filtered.length}");
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("[HomePage] build -> Iniciando build...");
    final productSearchViewModel = context.watch<ProductSearchViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.only(top: 36.0),
              child: searchBar.SearchBar(
                hintText: 'Search products...',
                onChanged: (value) {
                  productSearchViewModel.updateSearchQuery(value);
                  debugPrint("[HomePage] SearchBar onChanged -> $value");
                },
              ),
            ),
            const SizedBox(height: 16.0),

            // Filter Bar
            FilterBar(
              categories: _categoriesSortedByClicks,
              selectedCategories: _selectedCategories,
              onCategoriesSelected: (selected) {
                debugPrint("[HomePage] FilterBar onCategoriesSelected -> $selected");
                setState(() {
                  _selectedCategories = selected;
                });
              },
              onSortByDateSelected: (selectedOrder) {
                debugPrint("[HomePage] FilterBar onSortByDateSelected -> $selectedOrder");
                setState(() {
                  _sortOrder = selectedOrder;
                });
              },
              onSortByPriceSelected: (selectedOrder) {
                debugPrint("[HomePage] FilterBar onSortByPriceSelected -> $selectedOrder");
                setState(() {
                  _sortPrice = selectedOrder;
                });
              },
              onAcademicCalendarSelected: (bool isActive) {
                debugPrint("[HomePage] FilterBar onAcademicCalendarSelected -> $isActive");
                setState(() {
                  _academicCalendarActive = isActive;
                });
              },
            ),
            const SizedBox(height: 16.0),

            // Grid de productos
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: _productRepo.getProductsStream(),
                builder: (context, snapshot) {
                  debugPrint("[HomePage] StreamBuilder -> connectionState=${snapshot.connectionState}");
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    debugPrint("[HomePage] StreamBuilder -> Cargando...");
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    debugPrint("[HomePage] StreamBuilder -> No hay productos");
                    return const Center(
                      child: Text(
                        "No products added yet",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    );
                  }
                  final allProducts = snapshot.data!;
                  debugPrint("[HomePage] StreamBuilder -> allProducts.length=${allProducts.length}");

                  final filteredProducts = _filterProducts(allProducts, productSearchViewModel);
                  debugPrint("[HomePage] StreamBuilder -> filteredProducts.length=${filteredProducts.length}");

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onCategoryTap: (category) {
                          _incrementCategoryClick(category);
                        },
                        onProductTap: () {
                          _registerProductClick(product);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
      ),
    );
  }
}