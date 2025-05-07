import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senemarket/constants.dart';
import 'viewmodel/chat_viewmodel.dart';
import 'package:senemarket/domain/entities/chat_message.dart';

class ChatPage extends StatefulWidget {
  final String receiverName;
  const ChatPage({Key? key, required this.receiverName}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatViewModel>().addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    });
  }

  Future<void> _pickAndConfirmImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send this image?'),
        content: Image.file(file, width: 200, height: 200, fit: BoxFit.cover),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    if (confirm == true) await context.read<ChatViewModel>().sendImage(file);
  }

  void _showImageDetail(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(url))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final raw = vm.messages;
    final List<dynamic> items = [];
    DateTime? lastDate;
    for (var msg in raw) {
      final day = DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
      if (lastDate == null || day != lastDate) {
        items.add(day);
        lastDate = day;
      }
      items.add(msg);
    }

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        backgroundColor: AppColors.primary40,
        elevation: 0,
        title: Text(widget.receiverName, style: const TextStyle(fontFamily: 'Cabin', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary0)),
      ),
      body: Column(
        children: [
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                if (item is DateTime) {
                  final label = _formatDateHeader(item);
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                      child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  );
                }
                final msg = item as ChatMessage;
                final isMe = msg.senderId == vm.currentUserId;

                Widget content;
                if (msg.localImagePath != null || msg.imageUrl != null) {
                  final img = msg.localImagePath != null
                      ? Image.file(File(msg.localImagePath!), width: 200, height: 200, fit: BoxFit.cover)
                      : GestureDetector(onTap: () => _showImageDetail(msg.imageUrl!), child: Image.network(msg.imageUrl!, width: 200, height: 200, fit: BoxFit.cover));
                  content = Stack(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: img),
                      if (msg.status == MessageStatus.pending)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  );
                } else {
                  content = Text(msg.text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontFamily: 'Cabin', fontSize: 16));
                }

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary30.withOpacity(0.9) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0,2))],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        content,
                        const SizedBox(height: 4),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(DateFormat('HH:mm').format(msg.timestamp), style: TextStyle(fontSize: 12, color: isMe ? Colors.white70 : Colors.grey[600])),
                          const SizedBox(width: 4),
                          if (msg.senderId == vm.currentUserId) Icon(
                            msg.status == MessageStatus.pending ? Icons.access_time : msg.status == MessageStatus.sent ? Icons.check : Icons.done_all,
                            size: 14,
                            color: msg.status == MessageStatus.read ? Colors.blue : (isMe ? Colors.white70 : Colors.grey),
                          ),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary40, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0,-2))]),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.image, color: Colors.white), onPressed: _pickAndConfirmImage),
                Expanded(child: TextField(controller: _ctrl, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: 'Type a message...', hintStyle: const TextStyle(fontFamily: 'Cabin', fontSize: 16, color: Colors.grey), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical:12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)))),
                const SizedBox(width: 8),
                CircleAvatar(backgroundColor: AppColors.primary30, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () { context.read<ChatViewModel>().sendMessage(_ctrl.text); _ctrl.clear(); })),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateHeader(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 30) return DateFormat('MMM d').format(date);
  if (diff < 365) {
    final months = (diff / 30).floor();
    return months == 1 ? 'Last month' : '\$months months ago';
  }
  return DateFormat.yMMMd().format(date);
}
