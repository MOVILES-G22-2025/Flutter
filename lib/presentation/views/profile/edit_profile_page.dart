// lib/presentation/views/profile/edit_profile_page.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_field.dart';
import 'package:senemarket/presentation/widgets/form_fields/searchable_dropdown.dart';
import 'package:senemarket/presentation/widgets/global/error_text.dart';
import 'package:senemarket/core/services/custom_cache_manager.dart';

// 1️⃣ Importa tu repositorio unificado
import 'package:senemarket/data/repositories/user_repository_impl.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController     = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  String? _selectedCareer;
  String? _nameError;
  String? _semesterError;
  bool   _isLoading        = false;
  String? _profileImageUrl;
  bool   _isUploadingImage = false;

  late final UserRepositoryImpl _userRepo;
  late final String             _userId;
  late final String             _email;

  @override
  void initState() {
    super.initState();
    _userRepo = UserRepositoryImpl();
    final user = FirebaseAuth.instance.currentUser!;
    _userId = user.uid;
    _email  = user.email!;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final data = await _userRepo.getUserData();
    if (data != null) {
      _nameController.text     = data['name'] ?? '';
      _selectedCareer          = data['career'];
      _semesterController.text = data['semester']?.toString() ?? '';
      _profileImageUrl         = data['profileImageUrl'];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isUploadingImage = true);
    try {
      // 1) Copiar localmente
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = p.join(appDir.path, 'profile_$_userId.jpg');
      await File(picked.path).copy(localPath);
      String urlForDb = localPath;

      // 2) Si hay internet, subir a Storage y usar URL remota
      final status = await Connectivity().checkConnectivity();
      if (status != ConnectivityResult.none) {
        final storageRef = FirebaseStorage.instance.ref('profile_images/$_userId.jpg');
        await storageRef.putFile(File(picked.path));
        urlForDb = await storageRef.getDownloadURL();
      }

      // 3) Actualizar vía repositorio (cache local y cola offline)
      await _userRepo.updateUserData({
        'name'            : _nameController.text.trim(),
        'career'          : _selectedCareer!,
        'semester'        : _semesterController.text.trim(),
        'email'           : _email,
        'profileImageUrl' : urlForDb,
      });

      // 4) Reflejar en UI
      setState(() => _profileImageUrl = urlForDb);
    } catch (e) {
      // Manejo de error opcional
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading     = true;
      _nameError     = null;
      _semesterError = null;
    });

    final name     = _nameController.text.trim();
    final career   = _selectedCareer;
    final semester = _semesterController.text.trim();

    // — Validaciones —
    if (name.isEmpty) {
      setState(() { _nameError = ErrorMessages.allFieldsRequired; _isLoading = false; });
      return;
    }
    if (name.length > 40) {
      setState(() { _nameError = ErrorMessages.maxChar; _isLoading = false; });
      return;
    }
    if (career == null || career.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    final intSem = int.tryParse(semester);
    if (intSem == null || intSem < 1 || intSem > 20) {
      setState(() { _semesterError = ErrorMessages.semesterRange; _isLoading = false; });
      return;
    }

    try {
      // 4️⃣ Llamamos al repositorio unificado e incluimos imagen actual
      final payload = {
        'name'     : name,
        'career'   : career,
        'semester' : semester,
        'email'    : _email,
      };
      if (_profileImageUrl != null) {
        payload['profileImageUrl'] = _profileImageUrl!;
      }
      await _userRepo.updateUserData(payload);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Manejo de error opcional
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontFamily: 'Cabin', fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary0),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar con picker de imagen
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _isUploadingImage ? null : _pickAndUploadImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: _isUploadingImage
                          ? const CircularProgressIndicator()
                          : _profileImageUrl != null
                          ? ClipOval(
                        child: (_profileImageUrl!.startsWith('http')
                            ? CachedNetworkImage(
                          imageUrl: _profileImageUrl!,
                          cacheManager: CustomCacheManager.instance,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const CircularProgressIndicator(),
                          errorWidget: (_, __, ___) => const Icon(Icons.error),
                        )
                            : Image.file(
                          File(_profileImageUrl!),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )),
                      )
                          : const Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary30,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Nombre
            CustomTextField(
              controller: _nameController,
              label: 'Name',
              onChanged: (value) {
                if (value.length > 40) {
                  setState(() => _nameError = ErrorMessages.maxChar);
                } else {
                  setState(() => _nameError = null);
                }
              },
            ),
            ErrorText(_nameError),
            const SizedBox(height: 16),

            // Carrera
            SearchableDropdown(
              label: 'Career',
              items: Careers.careers,
              selectedItem: _selectedCareer,
              onChanged: (value) => setState(() => _selectedCareer = value),
            ),
            const SizedBox(height: 16),

            // Semestre
            CustomTextField(
              controller: _semesterController,
              label: 'Semester',
              isNumeric: true,
              onChanged: (value) {
                final intSem = int.tryParse(value);
                if (intSem != null && (intSem < 1 || intSem > 20)) {
                  setState(() => _semesterError = ErrorMessages.semesterRange);
                } else {
                  setState(() => _semesterError = null);
                }
              },
            ),
            ErrorText(_semesterError),
            const SizedBox(height: 32),

            // Botón Guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary30,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Save Changes',
                style: TextStyle(
                  fontFamily: 'Cabin',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
