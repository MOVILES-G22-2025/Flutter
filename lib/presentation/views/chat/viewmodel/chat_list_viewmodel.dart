
// lib/presentation/views/chat/viewmodel/chat_list_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ViewModel for fetching the list of users to start chats with.
class ChatListViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> users = [];
  bool isLoading = false;

  /// Fetches all users from Firestore except the current user.
  Future<void> fetchUsers(String currentUserId) async {
    try {
      isLoading = true;
      notifyListeners();

      final querySnapshot = await _firestore.collection('users').get();

      users = querySnapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'name': data['name'] ?? 'Unnamed',
        };
      })
          .toList();

    } catch (e) {
      print('Error fetching users: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}