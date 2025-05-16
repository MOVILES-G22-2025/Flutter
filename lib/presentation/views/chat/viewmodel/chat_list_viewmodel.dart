import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';    // ✔️ Añadir import
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../domain/entities/chat_message.dart';

class ChatListViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> users = [];
  int totalUnreadChats = 0;
  bool isLoading = false;

  StreamSubscription? _chatSubscription;

  void listenToChats(String currentUserId) {
    _chatSubscription?.cancel();

    // Primero comprobamos la conectividad
    Connectivity().checkConnectivity().then((status) {
      if (status == ConnectivityResult.none) {
        // ▶️ SIMULACIÓN: sin internet, mostramos un chat "local"
        users = [
          {
            'userId'      : 'offlineUser1',
            'name'        : 'Usuario Offline',
            'lastMessage' : 'Este mensaje viene de la cache local',
            'lastTimestamp': DateTime.now().subtract(Duration(hours: 2)),
            'lastSenderId': currentUserId,
            'status'      : MessageStatus.pending,
            'unreadCount' : 0,
            'imageUrl'    : null,
          },
          // ...puedes añadir más entradas para simular varios chats locales
        ];
        isLoading = false;
        notifyListeners();
      } else {
        // ▶️ Con internet, suscribirse a Firestore como antes
        isLoading = true;
        notifyListeners();
        _chatSubscription = _firestore
            .collection('chats')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((snapshot) {
          final docs = snapshot.docs;
          _processMessages(docs, currentUserId);
        });
      }
    });
  }

  void _processMessages(List<QueryDocumentSnapshot> docs, String currentUserId) async {
    // ... lógica existente para procesar mensajes remotos ...
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }
}
