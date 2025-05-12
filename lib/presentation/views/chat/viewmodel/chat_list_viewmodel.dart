import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../domain/entities/chat_message.dart';

class ChatListViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> users = [];
  int totalUnreadChats = 0;

  bool isLoading = false;

  StreamSubscription? _chatSubscription;

  void listenToChats(String currentUserId) {
    _chatSubscription?.cancel();

    _chatSubscription = _firestore
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs;
      _processMessages(docs, currentUserId);
    });
  }

  void _processMessages(List<QueryDocumentSnapshot> docs, String currentUserId) async {
    final Map<String, Map<String, dynamic>> lastMessages = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final sender = data['senderId'] as String?;
      final imageUrl = data['imageUrl'] as String?;
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
          'imageUrl': data['imageUrl'],
        };
      }
    }

    final List<Future<Map<String, dynamic>?>> futures = [];

    for (var entry in lastMessages.entries) {
      final userId = entry.key;
      final last = entry.value;

      futures.add(Future(() async {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (!userDoc.exists) return null;

        final userData = userDoc.data()!;
        final unreadCount = await _countUnreadMessages(currentUserId, userId);

        return {
          'userId': userId,
          'name': userData['name'] ?? 'Sin nombre',
          'lastTimestamp': last['timestamp'],
          'lastMessage': last['message'],
          'lastSenderId': last['senderId'],
          'status': last['status'],
          'unreadCount': unreadCount,
          'imageUrl': last['imageUrl'],
        };
      }));
    }

    final results = await Future.wait(futures);
    users = results.whereType<Map<String, dynamic>>().toList();

    totalUnreadChats = users.where((u) => u['unreadCount'] > 0).length;

    users.sort((a, b) =>
        (b['lastTimestamp'] as DateTime).compareTo(a['lastTimestamp'] as DateTime));

    notifyListeners();
  }

  Future<int> _countUnreadMessages(String myId, String otherId) async {
    final unreadSnap = await _firestore
        .collection('chats')
        .where('senderId', isEqualTo: otherId)
        .where('receiverId', isEqualTo: myId)
        .get();

    final unreadMessages = unreadSnap.docs.where((doc) => doc['status'] != 'read').toList();
    return unreadMessages.length;
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }
}