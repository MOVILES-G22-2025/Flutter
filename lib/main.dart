import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:senemarket/views/product-detail_view/product-detail_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();
  runApp(senemarket());
}

class senemarket extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProductDetailPage(),
      routes: {
        //'/signIn': (context) => const SignInPage(),

      },
    );
  }
}
