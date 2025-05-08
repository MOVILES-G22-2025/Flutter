// lib/domain/repositories/chat_repository.dart
import '../entities/chat_message.dart';

/// Contrato para operaciones de chat entre dos usuarios.
abstract class ChatRepository {
  /// Envía un mensaje (texto o imagen) con un ID propio.
  Future<void> sendMessage(ChatMessage message);

  /// Retorna un stream de la lista de mensajes ordenados por timestamp.
  Stream<List<ChatMessage>> getMessages(String userId1, String userId2);

  /// Marca un mensaje como leído en el backend.
  Future<void> markAsRead(String messageId);
}
