import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart' as constants;
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/presentation/views/products/viewmodel/edit_product_viewmodel.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_dropdown.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_field.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import '../../../core/services/custom_cache_manager.dart';
import '../../widgets/global/error_text.dart';
import '../../widgets/global/full_screen_image_page.dart';

class EditProductPage extends StatefulWidget {
  final Product product;

  const EditProductPage({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<String> _existingImages = [];   // Already uploaded image URLs
  List<String> _originalImages = [];   // For detecting deletions
  List<XFile?> _newImages = [];        // New images picked from gallery/camera

  String? _selectedCategory;
  String? _priceError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController.text = p.name;
    _priceController.text = p.price.toString();
    _descriptionController.text = p.description;
    _selectedCategory = p.category;
    _existingImages = List.from(p.imageUrls);
    _originalImages = List.from(p.imageUrls);
  }

  // Remove an existing image (from Firestore)
  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    if (_existingImages.length + _newImages.length >= 5) {
      _showSnackBar("Max 5 images allowed");
      return;
    }

    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _newImages.add(picked);
      });
    }
  }

  // Show message at the bottom
  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // View image in fullscreen (URL or local file)
  void _openFullScreen(dynamic image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          if (image is String) {
            return FullScreenImagePage(imageUrl: image);
          } else if (image is XFile) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.file(File(image.path)),
                ),
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }

  // Save product with updates
  Future<void> _saveChanges() async {
    final viewModel = context.read<EditProductViewModel>();
    final double? price = double.tryParse(_priceController.text);

    // Validate all fields
    if (price == null ||
        _nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedCategory == null ||
        (_existingImages.isEmpty && _newImages.isEmpty)) {
      _showSnackBar('Please fill all the fields');
      return;
    }

    // Create updated product object
    final updated = widget.product.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      price: price,
      category: _selectedCategory!,
      imageUrls: _existingImages,
    );

    // Detect which images were removed
    final imagesToDelete = _originalImages.where((url) => !_existingImages.contains(url)).toList();

    // Try to update
    final success = await viewModel.updateProduct(
      productId: widget.product.id,
      updatedProduct: updated,
      newImages: _newImages,
      imagesToDelete: imagesToDelete,
    );

    if (success) {
      Navigator.pop(context);
    } else {
      _showSnackBar("Error updating product.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EditProductViewModel>();

    return Scaffold(
      backgroundColor: constants.AppColors.primary50,
      appBar: AppBar(
        backgroundColor: constants.AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: constants.AppColors.primary0),
        title: const Text('Edit Product', style: TextStyle(
          fontFamily: 'Cabin',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: constants.AppColors.primary0,
        ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Image grid (existing + new)
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                // Existing images
                ..._existingImages.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () => _openFullScreen(entry.value),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: entry.value,
                            cacheManager: CustomCacheManager.instance,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[300],
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, size: 24, color: Colors.red),
                            ),
                          )
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => _removeExistingImage(entry.key),
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: constants.AppColors.primary30,
                              child: Icon(Icons.close, size: 20, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                }),

                // New images
                ..._newImages.asMap().entries.map((entry) {
                  final image = entry.value!;
                  return GestureDetector(
                    onTap: () => _openFullScreen(image),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(image.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _newImages.removeAt(entry.key));
                            },
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: constants.AppColors.primary30,
                              child: Icon(Icons.close, size: 20, color: Colors.white),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                }),
                // Button to add new image
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: constants.AppColors.primary30,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, size: 40, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Form fields
            CustomTextField(
              label: 'Name',
              controller: _nameController,
              onChanged: (value) {
                if (value.length > 40) {
                  setState(() => _nameError = constants.ErrorMessages.maxChar);
                } else {
                  setState(() => _nameError = null);
                }
              },
            ),
            ErrorText(_nameError),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Description',
              controller: _descriptionController,
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            CustomDropdown(
              label: 'Category',
              items: constants.ProductClassification.categories,
              selectedItem: _selectedCategory,
              onChanged: (val) {
                setState(() => _selectedCategory = val);
              },
            ),
            CustomTextField(controller: _priceController, label: 'Price', isNumeric: true,
              onChanged: (value) {
                final intPrice = int.tryParse(value);
                if (intPrice != null && (intPrice < 1000)) {
                  setState(() => _priceError = constants.ErrorMessages.priceRange);
                } else {
                  setState(() => _priceError = null);
                }
              },
            ),
            ErrorText(_priceError),

            const SizedBox(height: 20),

            // Save button
            ElevatedButton(

              onPressed: viewModel.isLoading || !_isFormValid() ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: constants.AppColors.primary30,

                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: viewModel.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save changes',
                style: TextStyle(
                  fontFamily: 'Cabin',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: constants.AppColors.primary50,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: const NavigationBarApp(selectedIndex: 4),
    );
  }

  // Validate all form fields and images
  bool _isFormValid() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text);
    final hasImages = _existingImages.isNotEmpty || _newImages.isNotEmpty;

    final nameValid = name.isNotEmpty && name.length <= 40;
    final priceValid = price != null && price >= 1000;
    final descriptionValid = _descriptionController.text.isNotEmpty;
    final categoryValid = _selectedCategory != null;

    return nameValid && priceValid && descriptionValid && categoryValid && hasImages;
  }

}
