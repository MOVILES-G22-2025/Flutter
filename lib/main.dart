import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/models/product_search_model.dart';
import 'package:senemarket/views/home_page.dart';
import 'package:senemarket/views/login_view/signin_page.dart';
import 'package:senemarket/views/login_view/signup_page.dart';
import 'package:senemarket/views/product_view/add_product_page.dart';
import 'package:senemarket/views/login_view/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Solicita permisos (importante para iOS)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // Obtiene el token FCM
  String? token = await messaging.getToken();
  if (token != null) {
    print("FCM Token: $token");

    // Si el usuario está autenticado, guarda el token en Firestore
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await setupFCM(); // Configura FCM antes de ejecutar la app
  runApp(SeneMarketApp());
}

class SeneMarketApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductSearchModel>(
      create: (_) => ProductSearchModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/signIn': (context) => const SignInPage(),
          '/signUp': (context) => const SignUpPage(),
          '/home': (context) => HomePage(),
          '/add_product': (context) => const AddProductPage(),
          // Eliminamos la ruta '/productDetail'
        },
      ),
    );
  }
}

