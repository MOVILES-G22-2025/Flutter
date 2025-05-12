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
  final _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  String? _category;
  final List<XFile?> _images = [];

  bool _isFormValid = false;
  bool _submitting = false;
  String? _nameError;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.draft.name);
    _descCtrl = TextEditingController(text: widget.draft.description);
    _priceCtrl = TextEditingController(text: widget.draft.price.toString());
    _category = constants.ProductClassification.categories.contains(widget.draft.category)
        ? widget.draft.category
        : null;
    // load existing image paths if any
    _loadImages();
    _nameCtrl.addListener(_validateForm);
    _descCtrl.addListener(_validateForm);
    _priceCtrl.addListener(_validateForm);
    _validateForm();
  }

  Future<void> _loadImages() async {
    final List<XFile> validImages = [];

    for (final path in widget.draft.imagePaths) {
      final file = File(path);
      if (await file.exists()) {
        validImages.add(XFile(path));
      }
    }

    setState(() {
      _images.clear();
      _images.addAll(validImages);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _validateForm() {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final priceText = _priceCtrl.text.trim();
    final price = double.tryParse(priceText);
    setState(() {
      _nameError = name.isEmpty
          ? 'Required'
          : (name.length > 40 ? constants.ErrorMessages.maxChar : null);
      _priceError = price == null
          ? 'Invalid'
          : (price < 1000 ? 'Minimum price is \$1000' : null);
      _isFormValid = _nameError == null &&
          desc.isNotEmpty &&
          _category != null &&
          _priceError == null &&
          _images.isNotEmpty;
    });
  }

  Future<void> _pickImage(ImageSource src) async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }
    final file = await _picker.pickImage(source: src, imageQuality: 80);
    if (file != null) {
      setState(() {
        _images.add(file);
        _validateForm();
      });
    }
  }

  Future<void> _publishDraft() async {
    if (!_isFormValid) return;
    setState(() => _submitting = true);
    // show loading dialog
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
      ),
      bottomNavigationBar: const NavigationBarApp(selectedIndex: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // image picker
            CustomImagePicker(
              onPickImageFromCamera: () => _pickImage(ImageSource.camera),
              onPickImageFromGallery: () => _pickImage(ImageSource.gallery),
              image: _images,
              onRemoveImage: (i) {
                setState(() {
                  _images.removeAt(i);
                  _validateForm();
                });
              },
            ),
            const SizedBox(height: 16),
            // Name
            CustomTextField(
              label: 'Name',
              controller: _nameCtrl,
              onChanged: (_) => _validateForm(),
            ),
            if (_nameError != null) ErrorText(_nameError),
            const SizedBox(height: 12),
            // Description
            CustomTextField(
              label: 'Description',
              controller: _descCtrl,
              onChanged: (_) => _validateForm(),
            ),
            const SizedBox(height: 12),
            // Category
            SearchableDropdown(
              label: 'Category',
              items: constants.ProductClassification.categories,
              selectedItem: _category,
              onChanged: (v) {
                setState(() {
                  _category = v;
                  _validateForm();
                });
              },
            ),
            const SizedBox(height: 12),
            // Price
            CustomTextField(
              label: 'Price',
              controller: _priceCtrl,
              isNumeric: true,
              onChanged: (_) => _validateForm(),
            ),
           ErrorText(_priceError),
            const SizedBox(height: 24),
            // Publish button
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
}
