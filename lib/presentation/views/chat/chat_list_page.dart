import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:senemarket/constants.dart';
import '../../../domain/entities/chat_message.dart';
import 'viewmodel/chat_list_viewmodel.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ChatListViewModel>();
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      vm.listenToChats(currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatListViewModel>();

    return Scaffold(
      backgroundColor: AppColors.primary50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary50,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Chats',
          style: TextStyle(
            fontFamily: 'Cabin',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary0,
          ),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.users.isEmpty
          ? const Center(child: Text('No chats yet.'))
          : ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: vm.users.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          thickness: 0.7,
          color: Colors.grey,
        ),
        itemBuilder: (ctx, i) {
          final chat = vm.users[i];
          final name = chat['name'] as String;
          final lastMessageRaw = chat['lastMessage'] as String? ?? '';
          final imageUrl = chat['imageUrl'] as String?;
          final isImage = lastMessageRaw.trim().isEmpty && imageUrl != null;
          final isMine = chat['lastSenderId'] ==
              FirebaseAuth.instance.currentUser?.uid;
          final status = chat['status'] as MessageStatus? ?? MessageStatus.sent;
          final unreadCount = chat['unreadCount'] as int? ?? 0;
          final showUnreadBadge = !isMine && unreadCount > 0;
          final DateTime? ts = chat['lastTimestamp'] as DateTime?;
          final timeLabel =
          ts != null ? DateFormat('hh:mm a').format(ts) : '';

          Widget lastMessageWidget;
          if (isMine) {
            lastMessageWidget = Row(
              children: [
                Icon(
                  status == MessageStatus.read ? Icons.done_all : Icons.check,
                  size: 16,
                  color: status == MessageStatus.read ? Colors.grey : Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: isImage
                      ? const Row(
                    children: [
                      Icon(Icons.image, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Image',
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    lastMessageRaw,
                    style: TextStyle(
                      fontFamily: 'Cabin',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          } else {
            lastMessageWidget = isImage
                ? Row(
              children: const [
                Icon(Icons.image, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Image',
                  style: TextStyle(
                    fontFamily: 'Cabin',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            )
                : Text(
              lastMessageRaw,
              style: TextStyle(
                fontFamily: 'Cabin',
                fontSize: 14,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pushNamed(
              context,
              '/chat',
              arguments: {
                'receiverId': chat['userId'],
                'receiverName': name,
              },
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary30,
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Cabin',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        lastMessageWidget,
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      if (showUnreadBadge)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary30,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const NavigationBarApp(
        selectedIndex: 1,
      ),
    );
  }
}