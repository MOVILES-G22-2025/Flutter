// lib/domain/repositories/chat_repository.dart
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<void> sendMessage(ChatMessage message);
  Stream<List<ChatMessage>> getMessages(String userId1, String userId2);
}

