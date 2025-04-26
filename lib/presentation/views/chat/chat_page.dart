// lib/presentation/views/chat/chat_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart';
import 'viewmodel/chat_viewmodel.dart';

class ChatPage extends StatefulWidget {
  final String receiverName;
  const ChatPage({Key? key, required this.receiverName}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary40,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary30,
              child: Text(widget.receiverName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.receiverName, style: const TextStyle(fontFamily: 'Cabin', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary0)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: vm.messages.length,
              itemBuilder: (_, i) {
                final msg = vm.messages[i];
                final isMe = msg.senderId == vm.currentUserId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary30.withOpacity(0.9) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0,2))],
                    ),
                    child: Text(msg.text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontFamily: 'Cabin', fontSize: 16)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary40, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0,-2))]),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _ctrl, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: 'Type a message...', hintStyle: const TextStyle(fontFamily: 'Cabin', fontSize: 16, color: Colors.grey), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)))),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary30,
                    child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () { vm.sendMessage(_ctrl.text); _ctrl.clear(); }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}