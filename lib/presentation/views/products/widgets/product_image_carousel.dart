import 'package:flutter/material.dart';
import '../../../widgets/global/full_screen_image_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senemarket/core/services/custom_cache_manager.dart';

/// Carousel to show product images.
/// User can swipe or tap arrows to navigate.
/// Tapping on image opens full screen preview.
class ProductImageCarousel extends StatefulWidget {
  final List<String> images;

  const ProductImageCarousel({
    Key? key,
    required this.images,
  }) : super(key: key);

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

    // Updates current page index when user scrolls
    _pageController.addListener(() {
      final nextPage = _pageController.page?.round() ?? 0;
      if (_currentPage != nextPage) {
        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // Good practice: clean up controller
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
    final totalImages = widget.images.length;

    return Container(
      padding: const EdgeInsets.only(top: 8, right: 15, bottom: 5),
      width: MediaQuery.of(context).size.width,
      height: 350,
      child: totalImages > 0
          ? Stack(
        children: [
          // Main carousel using PageView
          PageView.builder(
            controller: _pageController,
            itemCount: totalImages,
            itemBuilder: (context, index) {
              final imageUrl = widget.images[index];
              return GestureDetector(
                onTap: () => _openFullScreenImage(imageUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: CachedNetworkImage(  //Caching strategy
                      imageUrl: imageUrl,
                      //Almacenar e n cache local por 30 dias
                      cacheManager: CustomCacheManager.instance,
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error, size: 50, color: Colors.red),
                      ),
                    ),
                  ),

                ),
              );
            },
          ),

          // Left arrow (only if not on first page)
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
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                ),
              ),
            ),

          // Right arrow (only if not on last page)
          if (_currentPage < totalImages - 1)
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
                    child: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                ),
              ),
            ),
        ],
      )
      // Placeholder when no images
          : Container(
        width: 350,
        height: 350,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }
}
