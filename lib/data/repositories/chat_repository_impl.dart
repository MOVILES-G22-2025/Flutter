// lib/data/repositories/chat_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendMessage(ChatMessage message) async {
    await _firestore.collection('chats').add(message.toMap());
  }

  @override
  Stream<List<ChatMessage>> getMessages(String userId1, String userId2) {
    return _firestore
      .collection('chats')
      .where('senderId', whereIn: [userId1, userId2])
      .where('receiverId', whereIn: [userId1, userId2])
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(
        (doc) => ChatMessage.fromMap(doc.data(), doc.id),
      ).toList());
  }
}
