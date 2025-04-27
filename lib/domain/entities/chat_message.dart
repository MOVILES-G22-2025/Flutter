import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final String? imageUrl; // URL opcional de la imagen

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.imageUrl,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String documentId) {
    final ts = map['timestamp'] as Timestamp?;
    return ChatMessage(
      id: documentId,
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: map['message'] as String? ?? '',
      timestamp: ts?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'senderId': senderId,
      'receiverId': receiverId,
      'message': text,
      'timestamp': timestamp,
    };
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }
    return data;
  }
}
