// lib/presentation/views/products/add_product_page.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'package:senemarket/presentation/widgets/form_fields/custom_image_picker.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_field.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_dropdown.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import 'package:senemarket/constants.dart' as constants;

import '../../../data/local/models/draft_product.dart';
import '../../widgets/global/error_text.dart';
import 'viewmodel/add_product_viewmodel.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _images = [];

  static const _draftKey = 'current_add_draft';
  late final Box<DraftProduct> _draftBox;
  String? _selectedCategory;
  bool _isFormValid = false;
  String? _nameError;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _draftBox = Hive.box<DraftProduct>('draft_products');
    final draft = _draftBox.get(_draftKey);
    if (draft != null) {
       _nameController.text        = draft.name;
       _descriptionController.text = draft.description;
       _priceController.text       = draft.price.toString();
       _selectedCategory           = draft.category;
       _images.clear();
       _images.addAll(draft.imagePaths.map((p) => XFile(p)));
       _validateForm();
    }
    _nameController.addListener(_saveDraft);
    _descriptionController.addListener(_saveDraft);
    _priceController.addListener(_saveDraft);
  }

  void _saveDraft() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';
    final draft = _draftBox.get(_draftKey) ??
    DraftProduct(id: _draftKey, userId: userId);
    draft
    ..name        = _nameController.text.trim()
    ..description = _descriptionController.text.trim()
    ..price       = double.tryParse(_priceController.text.trim()) ?? 0.0
    ..category    = _selectedCategory ?? ''
    ..imagePaths  = _images.where((f) => f!=null).map((f) => f!.path).toList()
    ..lastUpdated = DateTime.now();
    draft.save();
  }

  void _validateForm() {
    final vm = context.read<AddProductViewModel>();
    final isOnline = vm.isOnline;
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final price = double.tryParse(priceText);
    setState(() {
      _nameError = name.length > 40 ? constants.ErrorMessages.maxChar : null;
      _priceError = price == null || price < 1000 ? 'Minimum price is \$1000' : null;
      _isFormValid = _nameError == null &&
          _priceError == null &&
          name.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _selectedCategory != null &&
          priceText.isNotEmpty &&
          _images.isNotEmpty;
    });
  }

  Future<void> _showOfflineConfirmation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
        backgroundColor: constants.AppColors.primary30,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Product saved offline. Will publish automatically when connectivity is restored',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }




  Future<void> _pickImageFromCamera() async {
    if (_images.length >= 5) {
      _showSnackBar("You can only upload up to 5 images");
      return;
    }
    final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _images.add(picked);
        _validateForm();
        _saveDraft();
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_images.length >= 5) {
      _showSnackBar("Max 5 images allowed");
      return;
    }
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _images.add(picked);
        _validateForm();
        _saveDraft();
      });
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveProduct() async {
    if (!_isFormValid) {
      _showSnackBar('Please fill in all the fields');
      return;
    }
    final vm = context.read<AddProductViewModel>();

    // OFFLINE
    if (!vm.isOnline) {
      await vm.saveProductOffline(
        images: _images,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      );
      // ▶️ Mostramos diálogo animado
      await _showOfflineConfirmation();
      // Navegar a Home limpiando stack
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      await _draftBox.delete(_draftKey);

      return;
    }

    // ONLINE
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          backgroundColor: Colors.white,
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

      await vm.addProduct(
        images: _images,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      );
      Navigator.pop(context); // cierra diálogo de carga

      if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty) {
        _showSnackBar(vm.errorMessage!);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
        await _draftBox.delete(_draftKey);

      }
    } catch (e) {
      Navigator.pop(context);
      _showSnackBar('Error while publishing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddProductViewModel>();
    return Scaffold(
      backgroundColor: constants.AppColors.primary50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: constants.AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: constants.AppColors.primary0),
        centerTitle: true,
        title: const Text('Add product', style: TextStyle(fontFamily: 'Cabin', fontSize: 24, fontWeight: FontWeight.bold, color: constants.AppColors.primary0)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CustomImagePicker(
                    onPickImageFromCamera: _pickImageFromCamera,
                    onPickImageFromGallery: _pickImageFromGallery,
                    image: _images,
                    onRemoveImage: (i) => setState(() { _images.removeAt(i); _validateForm(); }),
                  ),
                  CustomTextField(label: 'Name', controller: _nameController, onChanged: (_) => _validateForm()),
                  ErrorText(_nameError),
                  const SizedBox(height: 12),
                  CustomTextField(label: 'Description', controller: _descriptionController, onChanged: (_) => _validateForm()),
                  const SizedBox(height: 12),
                  CustomDropdown(label: 'Category', items: constants.ProductClassification.categories, selectedItem: _selectedCategory, onChanged: (v) => setState((){ _selectedCategory=v; _validateForm(); })),
                  const SizedBox(height: 12),
                  CustomTextField(controller: _priceController, label: 'Price', isNumeric: true, onChanged: (_) => _validateForm()),
                  ErrorText(_priceError),
                  const SizedBox(height: 20),
// Botón principal “Add”
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
                    onPressed: vm.isLoading ? null : _saveProduct,
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: constants.AppColors.primary50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

// Botón secundario “Guardar borrador”
                  TextButton.icon(
                    icon: const Icon(Icons.save_alt, color: constants.AppColors.primary30),
                    label: const Text(
                      'Save as a draft',
                      style: TextStyle(
                        color: constants.AppColors.primary30,
                        fontFamily: 'Cabin',
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () async {
                      final vm = context.read<AddProductViewModel>();
                      await vm.saveDraft(
                        name: _nameController.text.trim(),
                        description: _descriptionController.text.trim(),
                        category: _selectedCategory ?? '',
                        price: double.tryParse(_priceController.text.trim()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Borrador guardado')),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarApp(selectedIndex: 2),
    );
  }
}