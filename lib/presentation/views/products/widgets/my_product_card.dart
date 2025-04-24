import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/constants.dart';

import '../../../../core/services/custom_cache_manager.dart';

class MyProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MyProductCard({
    Key? key,
    required this.product,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  State<MyProductCard> createState() => _MyProductCardState();
}

class _MyProductCardState extends State<MyProductCard> {
  bool _showOptions = false;
  bool _isHovered = false;

  void _toggleOptions() {
    setState(() {
      _showOptions = !_showOptions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.product.imageUrls.isNotEmpty
        ? widget.product.imageUrls.first
        : null;

    return GestureDetector(
      onLongPress: _toggleOptions,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? AppColors.secondary20.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: _isHovered ? 10 : 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
                  child: (imageUrl != null)
                      ? CachedNetworkImage( //Caching strategy
                    imageUrl: imageUrl,
                    cacheManager: CustomCacheManager.instance,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey[300],
                      child:
                      const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error,
                          size: 40, color: Colors.red),
                    ),
                  )
                      : Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image,
                        size: 40, color: Colors.grey),
                  ),
                ),

                // Product Info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cabin',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.touch_app,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "\$ ${widget.product.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Options overlay
          if (_showOptions)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _toggleOptions();
                          widget.onEdit?.call();
                        },
                        child: const Center(
                          child: Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Cabin',
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 2, color: Colors.white24),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          _toggleOptions();
                          widget.onDelete?.call();
                        },
                        child: const Center(
                          child: Text(
                            "Delete",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Cabin',
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary30,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 2, color: Colors.white24),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 40,),
                      onPressed: _toggleOptions,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}