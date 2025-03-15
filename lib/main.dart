import 'package:flutter/material.dart';
import 'views/login_view/login_page.dart';
import 'views/home_page.dart';

void main() async {
  runApp(senemarket());
}

class senemarket extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SeneMarket',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}