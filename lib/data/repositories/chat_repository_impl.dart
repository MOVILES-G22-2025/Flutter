// lib/data/repositories/chat_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

/// Implementación de ChatRepository usando Firebase Firestore.
class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> sendMessage(ChatMessage message) {
    // Guarda el mensaje con un ID propio (UUID generado)
    return _firestore
        .collection('chats')
        .doc(message.id)
        .set(message.toMap());
  }

  @override
  Stream<List<ChatMessage>> getMessages(String userId1, String userId2) {
    // Obtiene todos los mensajes entre dos usuarios, ordenados cronológicamente
    return _firestore
        .collection('chats')
        .where('senderId', whereIn: [userId1, userId2])
        .where('receiverId', whereIn: [userId1, userId2])
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return ChatMessage.fromMap(doc.data(), doc.id);
    }).toList());
  }

  @override
  Future<void> markAsRead(String messageId) {
    // Actualiza el campo 'status' a 'read' para marcarlo como leído
    return _firestore
        .collection('chats')
        .doc(messageId)
        .update({'status': 'read'});
  }
}
