// lib/presentation/views/chat/viewmodel/chat_list_viewmodel.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../domain/entities/chat_message.dart';

/// ViewModel for fetching the list of chat contacts (users with at least one message),
/// ordered by most recent message first.
class ChatListViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> users = [];
  bool isLoading = false;

  StreamSubscription? _chatSubscription;

  void listenToChats(String currentUserId) {
    _chatSubscription?.cancel(); // cancelar si ya existe

    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs;
      // filtra y actualiza users con lógica actual
      _processMessages(docs, currentUserId);
    });
  }

  void _processMessages(List<QueryDocumentSnapshot> docs, String currentUserId) async {
    final Map<String, Map<String, dynamic>> lastMessages = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final sender = data['senderId'] as String?;
      final receiver = data['receiverId'] as String?;
      final ts = (data['timestamp'] as Timestamp?)?.toDate();
      final message = data['message'] as String? ?? '';
      final statusString = data['status'] as String? ?? 'sent';
      final status = MessageStatus.values.firstWhere(
            (e) => e.toString().split('.').last == statusString,
        orElse: () => MessageStatus.sent,
      );

      if (sender == null || receiver == null || ts == null) continue;

      String? otherUserId;
      if (sender == currentUserId) {
        otherUserId = receiver;
      } else if (receiver == currentUserId) {
        otherUserId = sender;
      }

      if (otherUserId == null || otherUserId == currentUserId) continue;

      final existing = lastMessages[otherUserId];
      if (existing == null || ts.isAfter(existing['timestamp'])) {
        lastMessages[otherUserId] = {
          'timestamp': ts,
          'message': message,
          'senderId': sender,
          'status': status,
        };
      }
    }

    final List<Map<String, dynamic>> updatedUsers = [];

    for (var entry in lastMessages.entries) {
      final userId = entry.key;
      final last = entry.value;
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) continue;

      final userData = userDoc.data()!;
      updatedUsers.add({
        'userId': userId,
        'name': userData['name'] ?? 'Sin nombre',
        'lastTimestamp': last['timestamp'],
        'lastMessage': last['message'],
        'lastSenderId': last['senderId'],
        'status': last['status'],
      });
    }

    updatedUsers.sort((a, b) =>
        (b['lastTimestamp'] as DateTime).compareTo(a['lastTimestamp'] as DateTime));

    users = updatedUsers;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }
}