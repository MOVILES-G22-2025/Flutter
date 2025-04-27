// lib/presentation/views/chat/viewmodel/chat_list_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ViewModel for fetching the list of chat contacts (users with at least one message),
/// ordered by most recent message first.
class ChatListViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> users = [];
  bool isLoading = false;

  /// Fetches users with whom the current user has exchanged at least one message,
  /// including the timestamp of the last message, and sorts them descending.
  Future<void> fetchUsers(String currentUserId) async {
    try {
      isLoading = true;
      notifyListeners();

      // 1) Obtener todos los mensajes donde el usuario es sender o receiver
      final chatSnap = await _firestore
          .collection('chats')
          .where('senderId', whereIn: [currentUserId])
          .get();
      final chatSnap2 = await _firestore
          .collection('chats')
          .where('receiverId', whereIn: [currentUserId])
          .get();

      // 2) Mapear contactos y su último timestamp
      final Map<String, DateTime> lastTimestamps = {};
      for (var doc in [...chatSnap.docs, ...chatSnap2.docs]) {
        final data = doc.data();
        final sender = data['senderId'] as String?;
        final receiver = data['receiverId'] as String?;
        final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        String? other;
        if (sender == currentUserId && receiver != null) other = receiver;
        if (receiver == currentUserId && sender != null) other = sender;
        if (other != null && other != currentUserId) {
          final prev = lastTimestamps[other];
          if (prev == null || ts.isAfter(prev)) {
            lastTimestamps[other] = ts;
          }
        }
      }

      // 3) Obtener datos de usuario y construir lista
      final List<Map<String, dynamic>> list = [];
      for (var entry in lastTimestamps.entries) {
        final id = entry.key;
        final last = entry.value;
        final userDoc = await _firestore.collection('users').doc(id).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          list.add({
            'userId': id,
            'name': data['name'] as String? ?? 'Unnamed',
            'lastTimestamp': last,
          });
        }
      }

      // 4) Ordenar por lastTimestamp descendente
      list.sort((a, b) {
        final ta = a['lastTimestamp'] as DateTime;
        final tb = b['lastTimestamp'] as DateTime;
        return tb.compareTo(ta);
      });

      users = list;
    } catch (e) {
      print('Error fetching chat contacts: \$e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
