// lib/presentation/views/chat/viewmodel/chat_viewmodel.dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// Envía una imagen: la sube a Firebase Storage y luego manda un mensaje con imageUrl.
  Future<void> sendImage(File file) async {
    // 1) Sube a Storage
    final path = 'chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child(path);
    final task = await ref.putFile(file);
    final url = await task.ref.getDownloadURL();

    // 2) Crea un ChatMessage con solo imageUrl
    final msg = ChatMessage(
      id: '',
      senderId: currentUserId,
      receiverId: otherUserId,
      text: '',           // ningún texto
      timestamp: DateTime.now(),
      imageUrl: url,      // URL de la imagen
    );
    await _chatRepo.sendMessage(msg);
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