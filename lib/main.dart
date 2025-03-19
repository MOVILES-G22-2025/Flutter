import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../views/home_page.dart';
import '../views/login_view/signin_page.dart';
import '../views/login_view/signup_page.dart';
import '../views/product_view/add_product_page.dart';
import 'views/login_view/login_page.dart';
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
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signIn': (context) => const SignInPage(),
        '/signUp': (context) => const SignUpPage(),
        '/home': (context) => HomePage(),
        '/add_product': (context) => const AddProductPage(),
        '/productDetail' :(context) => const ProductDetailPage(),

      },
    );
  }
}
