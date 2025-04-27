// lib/domain/entities/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { pending, sent, read }

/// Representa un mensaje de chat, con soporte para imagen local y estados.
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  /// URL remota de la imagen (si aplica)
  String? imageUrl;
  /// Ruta local temporal de la imagen al enviarse offline
  String? localImagePath;
  MessageStatus status;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.imageUrl,
    this.localImagePath,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String documentId) {
    final rawTs = map['timestamp'];
    DateTime ts;
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is DateTime) {
      ts = rawTs;
    } else {
      ts = DateTime.now();
    }

    final stateString = map['status'] as String? ?? 'sent';
    final status = MessageStatus.values.firstWhere(
          (e) => e.toString().split('.').last == stateString,
      orElse: () => MessageStatus.sent,
    );

    return ChatMessage(
      id: documentId,
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: map['message'] as String? ?? '',
      timestamp: ts,
      imageUrl: map['imageUrl'] as String?,
      localImagePath: null,
      status: status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': text,
      'timestamp': timestamp,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': status.toString().split('.').last,
    };
  }
}
