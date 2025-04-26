// lib/domain/entities/chat_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String documentId) {
    // Handle missing keys/fallbacks
    final messageText = (map['message'] as String?)
        ?? (map['text'] as String?)
        ?? '';
    final ts = map['timestamp'] as Timestamp?;
    return ChatMessage(
      id: documentId,
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: messageText,
      timestamp: ts?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': text,
      'timestamp': timestamp,
    };
  }
}