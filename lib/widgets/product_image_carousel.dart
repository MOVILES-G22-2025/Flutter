import 'package:flutter/material.dart';
import 'package:senemarket/widgets/full_screen_image_page.dart';

class ProductImageCarousel extends StatefulWidget {
  final List<String> images;

  const ProductImageCarousel({Key? key, required this.images})
      : super(key: key);

  @override
  _ProductImageCarouselState createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImagePage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8, right: 15, bottom: 5),
      width: MediaQuery.of(context).size.width,
      height: 350,
      child: widget.images.isNotEmpty
          ? Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final imageUrl = widget.images[index];
              return GestureDetector(
                onTap: () => _openFullScreenImage(imageUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
          // Flecha izquierda (si no es la primera página)
          if (_currentPage > 0)
            Positioned(
              left: 5,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn);
                  },
                ),
              ),
            ),
          // Flecha derecha (si no es la última página)
          if (_currentPage < widget.images.length - 1)
            Positioned(
              right: 5,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn);
                  },
                ),
              ),
            ),
        ],
      )
          : Container(
        width: 350,
        height: 350,
        color: Colors.grey[300],
        child: const Icon(
          Icons.image,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }
}
