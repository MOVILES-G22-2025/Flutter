// lib/presentation/views/chat/viewmodel/chat_viewmodel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:senemarket/domain/entities/chat_message.dart';
import 'package:senemarket/domain/repositories/chat_repository.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepo;
  final String currentUserId;
  final String otherUserId;

  List<ChatMessage> messages = [];
  bool isLoading = true;
  StreamSubscription<List<ChatMessage>>? _sub;

  ChatViewModel(this._chatRepo, this.currentUserId, this.otherUserId) {
    _sub = _chatRepo
        .getMessages(currentUserId, otherUserId)
        .listen((msgs) {
      messages = msgs;
      isLoading = false;
      notifyListeners();
    }, onError: (e) {
      // Firestore composite index may be required
      print('Error loading messages: \$e');
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = ChatMessage(
      id: '',
      senderId: currentUserId,
      receiverId: otherUserId,
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    await _chatRepo.sendMessage(msg);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}