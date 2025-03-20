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
      sound: true
  );
  print('User granted permission: ${settings.authorizationStatus}');

  // Obtiene y actualiza el token por primera vez
  await updateFCMToken();

  // Escucha cambios en el token y lo actualiza en Firestore
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    updateFCMToken(newToken);
  });
}

Future<void> updateFCMToken([String? newToken]) async {
  print("Intentando obtener el token...");
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token = newToken ?? await messaging.getToken();

  if (token != null) {
    print("FCM Token actualizado: $token");

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("Usuario autenticado: ${user.uid}");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));

      print("Token guardado en Firestore con éxito.");
    } else {
      print("⚠️ No hay usuario autenticado. No se guardó el token.");
    }
  } else {
    print("⚠️ No se pudo obtener el token de FCM.");
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


