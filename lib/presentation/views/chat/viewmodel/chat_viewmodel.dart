// lib/presentation/views/chat/viewmodel/chat_viewmodel.dart
import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:senemarket/domain/entities/chat_message.dart';
import 'package:senemarket/domain/repositories/chat_repository.dart';
import 'package:senemarket/core/services/connectivity_service.dart';
import 'package:senemarket/data/local/operation_queue.dart';
import '../../../../data/local/models/operation.dart';

/// ViewModel de chat con placeholders y reenvío filtrado por conversación
class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepo;
  final ConnectivityService _connectivity;
  final OperationQueue _opQueue;
  final String currentUserId;
  final String otherUserId;

  List<ChatMessage> messages = [];
  bool isLoading = true;
  StreamSubscription<List<ChatMessage>>? _sub;
  StreamSubscription<bool>? _connSub;

  ChatViewModel(
      this._chatRepo,
      this._connectivity,
      this._opQueue,
      this.currentUserId,
      this.otherUserId,
      ) {
    // 0) Cargar placeholders SOLO de este chat
    final pendingOps = _opQueue.pending().where((op) {
      if (op.type != OperationType.sendMessage) return false;
      final sender = op.payload['senderId'] as String?;
      final receiver = op.payload['receiverId'] as String?;
      return sender == currentUserId && receiver == otherUserId;
    });
    for (var op in pendingOps) {
      final payload = op.payload;
      final rawTs = payload['timestamp'];
      final ts = rawTs is String ? DateTime.parse(rawTs) : rawTs as DateTime;
      final msg = ChatMessage(
        id: op.id,
        senderId: payload['senderId'] as String,
        receiverId: payload['receiverId'] as String,
        text: payload['message'] as String,
        timestamp: ts,
        imageUrl: payload['imageUrl'] as String?,
        localImagePath: payload['localImagePath'] as String?,
        status: MessageStatus.pending,
      );
      messages.add(msg);
    }

    // 1) Escuchar mensajes en Firestore y combinarlos
    _sub = _chatRepo.getMessages(currentUserId, otherUserId).listen((remoteMsgs) {
      final placeholderMap = { for (var m in messages.where((m) => m.status == MessageStatus.pending)) m.id : m };
      final combined = <ChatMessage>[];
      for (var r in remoteMsgs) {
        if (placeholderMap.containsKey(r.id)) {
          placeholderMap.remove(r.id);
          combined.add(r);
        } else {
          combined.add(r);
        }
      }
      combined.addAll(placeholderMap.values);

      messages = combined;
      isLoading = false;
      notifyListeners();

      // Marcar lecturas
      for (var msg in messages) {
        if (msg.receiverId == currentUserId && msg.status == MessageStatus.sent) {
          markAsRead(msg.id);
        }
      }
    }, onError: (e) {
      print('Error loading messages: \$e');
    });

    // 2) Reintentar operaciones de ESTE chat al reconectar
    _connSub = _connectivity.isOnline$.listen((online) {
      if (online) _flushPending();
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final id = const Uuid().v4();
    final now = DateTime.now();
    final online = await _connectivity.isOnline$.first;
    final status = online ? MessageStatus.sent : MessageStatus.pending;

    final msg = ChatMessage(
      id: id,
      senderId: currentUserId,
      receiverId: otherUserId,
      text: text.trim(),
      timestamp: now,
      status: status,
    );
    messages.add(msg);
    notifyListeners();

    if (online) {
      try {
        await _chatRepo.sendMessage(msg);
      } catch (_) {
        _enqueueMessage(msg);
      }
    } else {
      _enqueueMessage(msg);
    }
  }

  Future<void> sendImage(File file) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final online = await _connectivity.isOnline$.first;
    final status = online ? MessageStatus.sent : MessageStatus.pending;

    // Placeholder local
    final msg = ChatMessage(
      id: id,
      senderId: currentUserId,
      receiverId: otherUserId,
      text: '',
      timestamp: now,
      imageUrl: null,
      localImagePath: file.path,
      status: status,
    );
    messages.add(msg);
    notifyListeners();

    // Subida/envío
    if (online) {
      try {
        final path = 'chat_images/${now.millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(path);
        final task = await ref.putFile(file);
        final url = await task.ref.getDownloadURL();

        msg.imageUrl = url;
        msg.localImagePath = null;
        msg.status = MessageStatus.sent;
        notifyListeners();

        await _chatRepo.sendMessage(msg);
      } catch (_) {
        _enqueueImageOp(msg, file.path, now);
      }
    } else {
      _enqueueImageOp(msg, file.path, now);
    }
  }

  void _enqueueMessage(ChatMessage msg) {
    final op = Operation(
      id: msg.id,
      type: OperationType.sendMessage,
      payload: msg.toMap(),
    );
    _opQueue.enqueue(op);
  }

  void _enqueueImageOp(ChatMessage msg, String localPath, DateTime timestamp) {
    final payload = {
      'senderId': msg.senderId,
      'receiverId': msg.receiverId,
      'message': msg.text,
      'timestamp': timestamp.toIso8601String(),
      'localImagePath': localPath,
    };
    final op = Operation(id: msg.id, type: OperationType.sendMessage, payload: payload);
    _opQueue.enqueue(op);
  }

  void _flushPending() async {
    final ops = _opQueue.pending().where((op) {
      if (op.type != OperationType.sendMessage) return false;
      final sender = op.payload['senderId'] as String?;
      final receiver = op.payload['receiverId'] as String?;
      return sender == currentUserId && receiver == otherUserId;
    });
    for (var op in ops) {
      final payload = op.payload;
      File? file;
      String? url;
      if (payload.containsKey('localImagePath')) {
        file = File(payload['localImagePath'] as String);
        final now = DateTime.now();
        final path = 'chat_images/${now.millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(path);
        final task = await ref.putFile(file);
        url = await task.ref.getDownloadURL();
      }
      final rawTs = payload['timestamp'];
      final ts = rawTs is String ? DateTime.parse(rawTs) : rawTs as DateTime;
      final msg = ChatMessage(
        id: op.id,
        senderId: payload['senderId'] as String,
        receiverId: payload['receiverId'] as String,
        text: payload['message'] as String,
        timestamp: ts,
        imageUrl: url,
        localImagePath: null,
        status: MessageStatus.sent,
      );
      try {
        await _chatRepo.sendMessage(msg);
        await _opQueue.remove(op.id);
        final idx = messages.indexWhere((m) => m.id == op.id);
        if (idx >= 0) {
          messages[idx] = msg;
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  Future<void> markAsRead(String messageId) async {
    await _chatRepo.markAsRead(messageId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}
