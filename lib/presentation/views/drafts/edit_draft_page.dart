// lib/presentation/views/drafts/edit_draft_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart' as constants;
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/data/local/models/draft_product.dart';
import 'package:senemarket/presentation/views/drafts/viewmodel/edit_draft_viewmodel.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_image_picker.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_field.dart';
import 'package:senemarket/presentation/widgets/form_fields/searchable_dropdown.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import '../../widgets/global/error_text.dart';

class EditDraftPage extends StatefulWidget {
  final DraftProduct draft;

  const EditDraftPage({Key? key, required this.draft}) : super(key: key);

  @override
  _EditDraftPageState createState() => _EditDraftPageState();
}

class _EditDraftPageState extends State<EditDraftPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String? _category;
  final List<XFile?> _images = [];
  bool _submitting = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.draft.name;
    _descCtrl.text = widget.draft.description;
    _priceCtrl.text = widget.draft.price.toString();
    _category = widget.draft.category;
    _images.addAll(widget.draft.imagePaths.map((p) => XFile(p)));
    _validateForm();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _nameCtrl.text.isNotEmpty &&
          _descCtrl.text.isNotEmpty &&
          _priceCtrl.text.isNotEmpty &&
          _category != null &&
          _images.isNotEmpty;
    });
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _images.addAll(images);
        _validateForm();
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _validateForm();
    });
  }

  Future<void> _saveDraft() async {
    if (!_isFormValid) return;
    
    final vm = context.read<EditDraftViewModel>();
    await vm.updateDraft(
      draftId: widget.draft.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category!,
      price: double.tryParse(_priceCtrl.text.trim()),
      images: _images,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved')),
    );
    Navigator.pop(context);
  }

  Future<void> _publishDraft() async {
    if (!_isFormValid) return;
    setState(() => _submitting = true);
    
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
            Text("Publishing draft..."),
          ],
        ),
      ),
    );

    final vm = context.read<EditDraftViewModel>();
    final price = double.parse(_priceCtrl.text.trim());
    final product = Product(
      id: '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category!,
      price: price,
      imageUrls: [],
      sellerName: '',
      favoritedBy: [],
      timestamp: DateTime.now(),
      userId: widget.draft.userId,
    );

    final ok = await vm.publishDraft(product: product, newImages: _images);
    Navigator.of(context, rootNavigator: true).pop(); // close dialog
    setState(() => _submitting = false);

    if (ok) {
      await widget.draft.delete();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft published')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error publishing draft')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: constants.AppColors.primary50,
      appBar: AppBar(
        backgroundColor: constants.AppColors.primary50,
        elevation: 0,
        iconTheme: const IconThemeData(color: constants.AppColors.primary0),
        centerTitle: true,
        title: const Text(
          'Edit draft',
          style: TextStyle(
            fontFamily: 'Cabin',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: constants.AppColors.primary0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDraft,
          ),
        ],
      ),
      bottomNavigationBar: const NavigationBarApp(selectedIndex: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              controller: _nameCtrl,
              label: 'Name',
              onChanged: (_) => _validateForm(),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descCtrl,
              label: 'Description',
              onChanged: (_) => _validateForm(),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _priceCtrl,
              label: 'Price',
              isNumeric: true,
              onChanged: (_) => _validateForm(),
            ),
            const SizedBox(height: 16),
            SearchableDropdown(
              label: 'Category',
              selectedItem: _category,
              items: const ['Electronics', 'Clothing', 'Books', 'Other'],
              onChanged: (value) {
                setState(() {
                  _category = value;
                  _validateForm();
                });
              },
            ),
            const SizedBox(height: 16),
            CustomImagePicker(
              image: _images,
              onPickImageFromCamera: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _images.add(image);
                    _validateForm();
                  });
                }
              },
              onPickImageFromGallery: () async {
                final ImagePicker picker = ImagePicker();
                final List<XFile> images = await picker.pickMultiImage();
                if (images.isNotEmpty) {
                  setState(() {
                    _images.addAll(images);
                    _validateForm();
                  });
                }
              },
              onRemoveImage: _removeImage,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormValid
                    ? constants.AppColors.primary30
                    : constants.AppColors.secondary40,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitting || !_isFormValid ? null : _publishDraft,
              child: _submitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text(
                'Publish',
                style: TextStyle(
                  fontFamily: 'Cabin',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }
}
