import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:senemarket/data/local/models/draft_product.dart';
import 'package:senemarket/domain/entities/product.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';
import 'package:senemarket/constants.dart';

class CompleteDraftPage extends StatefulWidget {
  final String draftId;

  const CompleteDraftPage({Key? key, required this.draftId}) : super(key: key);

  @override
  State<CompleteDraftPage> createState() => _CompleteDraftPageState();
}

class _CompleteDraftPageState extends State<CompleteDraftPage> {
  List<XFile?> _selectedImages = [];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    setState(() {
      _selectedImages = images;
    });
  }

  Future<void> _publishDraft() async {
    final box = Hive.box<DraftProduct>('draft_products');
    final draft = box.get(widget.draftId);

    if (draft == null) return;

    final product = Product(
      id: '',
      name: draft.name,
      description: draft.description,
      category: draft.category,
      price: draft.price,
      userId: '',
      sellerName: '',
      imageUrls: [],
      favoritedBy: [],
      timestamp: null,
    );

    final repo = context.read<ProductRepository>();
    await repo.addProduct(images: _selectedImages, product: product);

    await box.delete(widget.draftId);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Producto publicado correctamente")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = Hive.box<DraftProduct>('draft_products').get(widget.draftId);

    if (draft == null) {
      return const Scaffold(
        body: Center(child: Text("Borrador no encontrado")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Completar publicación"),
        backgroundColor: AppColors.primary30,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nombre: ${draft.name}", style: const TextStyle(fontSize: 18)),
            Text("Categoría: ${draft.category}", style: const TextStyle(fontSize: 18)),
            Text("Precio: \$${draft.price}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text("Descripción:", style: const TextStyle(fontSize: 16)),
            Text(draft.description),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              label: const Text("Seleccionar imágenes"),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedImages.map((img) {
                return img != null
                    ? Image.file(File(img.path), height: 80, width: 80, fit: BoxFit.cover)
                    : const SizedBox.shrink();
              }).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedImages.isEmpty ? null : _publishDraft,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary30,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Publicar ahora"),
            ),
          ],
        ),
      ),
    );
  }
}