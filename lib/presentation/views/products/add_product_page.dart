import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:senemarket/presentation/widgets/form_fields/custom_image_picker.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_textfield.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_dropdown.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import 'package:senemarket/constants.dart' as constants;

import 'viewmodel/add_product_viewmodel.dart';

/// This page allows the user to add a new product to the marketplace.
/// It includes form fields for product name, price, description, category, and images.
class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  int _selectedIndex = 2;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _images = [];

  String? _selectedCategory;
  bool _isFormValid = false;

  /// Validates that all required fields are filled and at least one image is added.
  void _validateForm() {
    setState(() {
      _isFormValid = _images.isNotEmpty &&
          _nameController.text.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _selectedCategory != null &&
          _priceController.text.isNotEmpty;
    });
  }

  /// Picks an image from the camera, up to 5 allowed.
  Future<void> _pickImageFromCamera() async {
    if (_images.length >= 5) {
      _showSnackBar("You can only upload up to 5 images");
      return;
    }
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _images.add(pickedImage);
        _validateForm();
      });
    }
  }

  /// Picks an image from the gallery, up to 5 allowed.
  Future<void> _pickImageFromGallery() async {
    if (_images.length >= 5) {
      _showSnackBar("You can only upload up to 5 images");
      return;
    }
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _images.add(pickedImage);
        _validateForm();
      });
    }
  }

  /// Displays a simple snackbar message.
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Submits the form and uploads the product.
  Future<void> _saveProduct() async {
    final addProductVM = context.read<AddProductViewModel>();

    if (_isFormValid) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Publishing product..."),
              ],
            ),
          ),
        );

        final parsedPrice = double.tryParse(_priceController.text) ?? 0.0;

        await addProductVM.addProduct(
          images: _images,
          name: _nameController.text,
          description: _descriptionController.text,
          category: _selectedCategory!,
          price: parsedPrice,
        );

        Navigator.pop(context); // Close loading dialog

        if (addProductVM.errorMessage != null && addProductVM.errorMessage!.isNotEmpty) {
          _showSnackBar(addProductVM.errorMessage!);
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        Navigator.pop(context);
        _showSnackBar('Error while publishing the product: $e');
      }
    } else {
      _showSnackBar('Please fill in all the fields');
    }
  }

  /// Handles bottom navigation bar interactions.
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/chats');
        break;
      case 2:
        break; // Already on AddProduct
      case 3:
        Navigator.pushReplacementNamed(context, '/favorites');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  /// UI Build method for the product form.
  @override
  Widget build(BuildContext context) {
    final addProductVM = context.watch<AddProductViewModel>();
    final isLoading = addProductVM.isLoading;

    return Scaffold(
      backgroundColor: constants.AppColors.primary50,
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button
        backgroundColor: constants.AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: constants.AppColors.primary0),
        centerTitle: true,
        title: const Text(
          'Add product',
          style: TextStyle(
            fontFamily: 'Cabin',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: constants.AppColors.primary0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  CustomImagePicker(
                    onPickImageFromCamera: _pickImageFromCamera,
                    onPickImageFromGallery: _pickImageFromGallery,
                    image: _images,
                  ),
                  CustomTextField(
                    hintText: 'Name',
                    controller: _nameController,
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    hintText: 'Description',
                    controller: _descriptionController,
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 12),
                  CustomDropdown(
                    label: 'Category',
                    items: constants.ProductClassification.categories,
                    selectedItem: _selectedCategory,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                        _validateForm();
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    hintText: 'Price',
                    controller: _priceController,
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid
                          ? constants.AppColors.primary30
                          : constants.AppColors.secondary40,
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                      textStyle: const TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: isLoading ? null : _saveProduct,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: constants.AppColors.primary50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
      ),
    );
  }
}
