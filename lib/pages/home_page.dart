// lib/pages/home_page.dart
import 'package:flutter/material.dart' hide SearchBar;
import 'package:senemarket/common/search_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  // Carousel superior: banners que ocupan toda la pantalla con padding y curvatura.
  Widget _buildTopCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: SizedBox(
          height: 200,
          child: PageView(
            children: const [
              _CarouselItem(color: Colors.red, text: 'Banner 1'),
              _CarouselItem(color: Colors.blue, text: 'Banner 2'),
              _CarouselItem(color: Colors.green, text: 'Banner 3'),
            ],
          ),
        ),
      ),
    );
  }

  // Lista vertical de secciones con carouseles horizontales
  Widget _buildVerticalSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCarousel('Section 1'),
        _buildSectionCarousel('Section 2'),
        _buildSectionCarousel('Section 3'),
      ],
    );
  }

  // Cada sección: título y un carousel horizontal de productos
  Widget _buildSectionCarousel(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: _ProductCard(title: 'Product 1'),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: _ProductCard(title: 'Product 2'),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: _ProductCard(title: 'Product 3'),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: _ProductCard(title: 'Product 4'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Puedes dejar el AppBar transparente o eliminarlo si deseas que el SearchBar esté pegado al top.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      // Estructuramos el body en una Column:
      // 1. El SearchBar (fijo en la parte superior)
      // 2. El resto del contenido scrollable
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Fila superior: SearchBar + botón de carrito
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Expanded(
                    child: SearchBar(hintText: 'Search for a product'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      // Acción del carrito
                    },
                  ),
                ],
              ),
            ),
            // El resto del contenido es scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTopCarousel(),
                    const SizedBox(height: 16),
                    _buildVerticalSections(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para cada ítem del carousel superior
class _CarouselItem extends StatelessWidget {
  final Color color;
  final String text;

  const _CarouselItem({Key? key, required this.color, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}

// Widget para cada producto en el carousel horizontal de cada sección
class _ProductCard extends StatelessWidget {
  final String title;
  const _ProductCard({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(title),
      ),
    );
  }
}
