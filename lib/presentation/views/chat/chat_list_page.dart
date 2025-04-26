// lib/presentation/views/chat/chat_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:senemarket/constants.dart';
import 'viewmodel/chat_list_viewmodel.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    // Delayed fetch to avoid notifyListeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ChatListViewModel>();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      vm.fetchUsers(currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatListViewModel>();

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(fontFamily: 'Cabin', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary50,
        elevation: 0,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.users.isEmpty
          ? const Center(child: Text('No users available.'))
          : ListView.builder(
        itemCount: vm.users.length,
        itemBuilder: (ctx, i) {
          final u = vm.users[i];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary30,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(u['name'], style: const TextStyle(fontFamily: 'Cabin', fontSize: 16)),
            onTap: () => Navigator.pushNamed(
              context, '/chat',
              arguments: {
                'receiverId': u['userId'],
                'receiverName': u['name'],
              },
            ),
          );
        },
      ),
    );
  }
}