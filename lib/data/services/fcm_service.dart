// lib/data/services/fcm_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static Future<void> setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicita permisos (importante para iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Obtiene y actualiza el token por primera vez
    await updateFCMToken();

    // Escucha cambios en el token y lo actualiza en Firestore
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      updateFCMToken(newToken);
    });
  }

  static Future<void> updateFCMToken([String? newToken]) async {
    print("Intentando obtener el token FCM...");
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
}
