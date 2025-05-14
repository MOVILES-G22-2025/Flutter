import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/widgets/form_fields/custom_field.dart';
import 'package:senemarket/presentation/widgets/form_fields/searchable_dropdown.dart';
import 'package:senemarket/presentation/widgets/global/error_text.dart';
import 'package:senemarket/core/services/custom_cache_manager.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  String? _selectedCareer;
  String? _nameError;
  String? _semesterError;
  bool _isLoading = false;
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc.data()?['name'] ?? '';
          _selectedCareer = doc.data()?['career'];
          _semesterController.text = doc.data()?['semester'] ?? '';
          _profileImageUrl = doc.data()?['profileImageUrl'];
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storageRef =
          FirebaseStorage.instance.ref().child('profile_images/${user.uid}.jpg');
      await storageRef.putFile(File(picked.path));
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
      });

      setState(() {
        _profileImageUrl = downloadUrl;
      });
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _nameError = null;
      _semesterError = null;
    });

    final name = _nameController.text.trim();
    final career = _selectedCareer;
    final semester = _semesterController.text.trim();

    // Validate name
    if (name.isEmpty) {
      setState(() {
        _nameError = ErrorMessages.allFieldsRequired;
        _isLoading = false;
      });
      return;
    }
    if (name.length > 40) {
      setState(() {
        _nameError = ErrorMessages.maxChar;
        _isLoading = false;
      });
      return;
    }

    // Validate career
    if (career == null || career.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Validate semester
    final intSemester = int.tryParse(semester);
    if (intSemester == null || intSemester < 1 || intSemester > 20) {
      setState(() {
        _semesterError = ErrorMessages.semesterRange;
        _isLoading = false;
      });
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': name,
          'career': career,
          'semester': semester,
        });
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Cabin',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary0),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: _isUploadingImage
                          ? const CircularProgressIndicator()
                          : _profileImageUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: _profileImageUrl!,
                                    cacheManager: CustomCacheManager.instance,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.error),
                                  ),
                                )
                              : const Icon(Icons.person,
                                  size: 50, color: Colors.grey),
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
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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

            SearchableDropdown(
              label: 'Career',
              items: Careers.careers,
              selectedItem: _selectedCareer,
              onChanged: (String? career) {
                setState(() {
                  _selectedCareer = career;
                });
              },
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _semesterController,
              label: 'Semester',
              isNumeric: true,
              onChanged: (value) {
                final intSemester = int.tryParse(value);
                if (intSemester != null && (intSemester < 1 || intSemester > 20)) {
                  setState(() => _semesterError = ErrorMessages.semesterRange);
                } else {
                  setState(() => _semesterError = null);
                }
              },
            ),
            ErrorText(_semesterError),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary30,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _semesterController.dispose();
    super.dispose();
  }
} 