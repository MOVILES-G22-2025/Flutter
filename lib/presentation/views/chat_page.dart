import 'package:flutter/material.dart';
import '../widgets/global/navigation_bar.dart'; // ← tu barra


class ChatsScreen extends StatelessWidget {
  const ChatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: const Center(
        child: Text(
          "You don't have chats",
          style: TextStyle(fontSize: 18),
        ),
      ),
      bottomNavigationBar: const NavigationBarApp(selectedIndex: 1),
    );
  }
}

