// lib/presentation/widgets/custom_image_picker.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senemarket/constants.dart';

class CustomImagePicker extends StatelessWidget {
  final Future<void> Function() onPickImageFromCamera;
  final Future<void> Function() onPickImageFromGallery;
  final List<XFile?> image;
  final void Function(int) onRemoveImage; // NUEVO

  const CustomImagePicker({
    Key? key,
    required this.onPickImageFromCamera,
    required this.onPickImageFromGallery,
    required this.image,
    required this.onRemoveImage, // NUEVO
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: onPickImageFromCamera,
              icon: const Icon(Icons.camera_alt, color: AppColors.primary0),
              label: const Text(
                "Take photo",
                style: TextStyle(fontFamily: 'Cabin', color: AppColors.primary0),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary0),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onPickImageFromGallery,
              icon: const Icon(Icons.file_upload, color: AppColors.primary0),
              label: const Text(
                "Upload images",
                style: TextStyle(fontFamily: 'Cabin', color: AppColors.primary0),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary0),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Muestra las imágenes seleccionadas
        if (image.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: image.asMap().entries.map((entry) {
                int index = entry.key;
                XFile? imageFile = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          image: DecorationImage(
                            image: FileImage(File(imageFile!.path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Botón de eliminar (X)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
