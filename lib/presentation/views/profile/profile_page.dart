// lib/presentation/views/profile/profile_page.dart
import 'dart:io'; // necesario al principio

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';
import 'package:senemarket/core/services/custom_cache_manager.dart';

import 'package:senemarket/data/repositories/user_repository_impl.dart';
import 'package:senemarket/presentation/views/profile/payment_methods_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserRepositoryImpl _userRepo = UserRepositoryImpl();
  final int _selectedIndex = 4;
  String _userName = 'User';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadLocalUser();
  }

  Future<void> _loadLocalUser() async {
    final data = await _userRepo.getUserData();
    if (data != null) {
      setState(() {
        _userName        = data['name'] ?? 'User';
        _profileImageUrl = data['profileImageUrl'];
      });
    }
  }

  Future<void> _logout() async {
    // Opcional: detener SyncService si lo usas
    // SyncService.instance.dispose();
    await FirebaseAuth.instance.signOut();
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    const routes = ['/home', '/chats', '/add_product', '/favorites', '/edit_profile'];
    Navigator.pushReplacementNamed(context, routes[index]);
  }

  Widget _buildOptionTile(String text, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Cabin',
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary50,
      bottomNavigationBar: NavigationBarApp(selectedIndex: _selectedIndex),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cabin',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              child: _profileImageUrl != null
                  ? ClipOval(
                child: (() {
                  final url = _profileImageUrl!;
                  if (url.startsWith('http')) {
                    // URL de internet (o cache)
                    return CachedNetworkImage(
                      imageUrl: url,
                      cacheManager: CustomCacheManager.instance,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_,__) =>
                      const CircularProgressIndicator(),
                      errorWidget: (_,__,___) =>
                      const Icon(Icons.error),
                    );
                  } else {
                    // Ruta local de fichero
                    return Image.file(
                      File(url),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    );
                  }
                })(),
              )
                  : const Icon(Icons.person, size: 50, color: Colors.white),
            ),

      ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Hello, $_userName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cabin',
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile('Edit profile', Icons.person, () {
              Navigator.pushNamed(context, '/edit_profile')
                  .then((_) => _loadLocalUser());
            }),
            _buildOptionTile('My products', Icons.shopping_bag, () {
              Navigator.pushNamed(context, '/my_products');
            }),
            _buildOptionTile('My drafts', Icons.pending_actions, () {
              Navigator.pushNamed(context, '/drafts');
            }),
            _buildOptionTile('Favorites', Icons.favorite, () {
              Navigator.pushNamed(context, '/favorites');
            }),
            _buildOptionTile('Métodos de pago', Icons.payment, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentMethodsScreen(
                    currentUserId: FirebaseAuth.instance.currentUser!.uid,
                  ),
                ),
              );
            }),
            const SizedBox(height: 90),
            Positioned(
              bottom: 16,
              right: 0,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      bottomLeft: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
