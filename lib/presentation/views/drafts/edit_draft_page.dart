import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart' as constants;
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/presentation/views/drafts/viewmodel/edit_draft_viewmodel.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_dropdown.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_textfield.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';

import '../../../data/local/models/draft_product.dart';

class EditDraftPage extends StatefulWidget {
  final DraftProduct draft;

  const EditDraftPage({super.key, required this.draft});

  @override
  State<EditDraftPage> createState() => _EditDraftPageState();
}

class _EditDraftPageState extends State<EditDraftPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _images = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.draft.name;
    _descriptionController.text = widget.draft.description;
    _priceController.text = widget.draft.price.toString();
    _selectedCategory = widget.draft.category;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 5) {
      _showSnackBar("Max 5 images allowed.");
      return;
    }
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() => _images.add(picked));
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _isFormValid() {
    final price = double.tryParse(_priceController.text);
    return _nameController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _selectedCategory != null &&
        price != null &&
        _images.isNotEmpty;
  }

  Future<void> _publishDraft() async {
    final vm = context.read<EditDraftViewModel>();
    final price = double.tryParse(_priceController.text);

    if (!_isFormValid()) {
      _showSnackBar('Please complete all fields and add at least one image.');
      return;
    }

    final product = Product(
      id: '',
      name: _nameController.text,
      description: _descriptionController.text,
      price: price!,
      category: _selectedCategory!,
      imageUrls: [],
      sellerName: '',
      favoritedBy: [],
      userId: widget.draft.userId,
    );

    final success = await vm.publishDraft(
      product: product,
      newImages: _images,
    );

    if (success) {
      await widget.draft.delete();
      Navigator.pop(context);
    } else {
      _showSnackBar("Failed to publish draft.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditDraftViewModel>();

    return Scaffold(
      backgroundColor: constants.AppColors.primary50,
      appBar: AppBar(
        backgroundColor: constants.AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: constants.AppColors.primary0),
        title: const Text('Publish Draft', style: TextStyle(fontFamily: 'Cabin', color: Colors.black, fontSize: 24)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                ..._images.asMap().entries.map((entry) {
                  final image = entry.value!;
                  return Stack(
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
                          onTap: () => setState(() => _images.removeAt(entry.key)),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: constants.AppColors.primary30,
                            child: Icon(Icons.close, size: 20, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                }),
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
            CustomTextField(
              label: 'Name',
              controller: _nameController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Description',
              controller: _descriptionController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CustomDropdown(
              label: 'Category',
              items: constants.ProductClassification.categories,
              selectedItem: _selectedCategory,
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Price',
              controller: _priceController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: vm.isLoading || !_isFormValid() ? null : _publishDraft,
              style: ElevatedButton.styleFrom(
                backgroundColor: constants.AppColors.primary30,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: vm.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Add',
                  style: TextStyle(fontFamily: 'Cabin', color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: const NavigationBarApp(selectedIndex: 4),
    );
  }
}
