import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../common/navigation_bar.dart';
import '../../constants.dart';
import 'custom_dropdown.dart';
import 'custom_image.dart';
import 'custom_textfield.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

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

  void _validateForm() {
    setState(() {
      _isFormValid = _images.isNotEmpty &&
          _nameController.text.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _selectedCategory != null &&
          _priceController.text.isNotEmpty;
    });
  }

  Future<void> _pickImageFromCamera() async {
    if (_images.length >= 5) {
      _showSnackBar("You can only upload up to 5 images");
      return;
    }

    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedImage != null) {
      setState(() {
        _images.add(pickedImage);
        _validateForm();
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_images.length >= 5) {
      _showSnackBar("You can only upload up to 5 images");
      return;
    }

    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _images.add(pickedImage);
        _validateForm();
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary0),
        centerTitle: true,
        title: const Text(
          'Add product',
          style: TextStyle(
            fontFamily: 'Cabin',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                items: ProductClassification.categories,
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
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? AppColors.primary30
                        : AppColors.secondary40,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 16),
                    textStyle: const TextStyle(
                      fontFamily: 'Cabin',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _isFormValid
                      ? () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/home',
                            arguments: {
                              "image": _images.first?.path,
                              "name": _nameController.text,
                              "price": _priceController.text,
                            },
                          );
                        }
                      : null,
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      fontFamily: 'Cabin',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary50,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
