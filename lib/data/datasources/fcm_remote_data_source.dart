import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// This class manages Firebase Cloud Messaging (FCM) setup and token updates.
/// It saves the device's token to Firestore to allow push notifications.
class FCMRemoteDataSource {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FCMRemoteDataSource({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Requests FCM permissions and sets up token updates.
  Future<void> setupFCM() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    await updateFCMToken();

    // Listen for new tokens (e.g., when refreshed)
    _messaging.onTokenRefresh.listen((newToken) {
      updateFCMToken(newToken);
    });
  }

  /// Gets the FCM token and stores it in the user's Firestore document.
  Future<void> updateFCMToken([String? newToken]) async {
    print("Intentando obtener el token FCM...");
    final token = newToken ?? await _messaging.getToken();

    if (token != null) {
      print("FCM Token actualizado: $token");

      final user = _auth.currentUser;
      if (user != null) {
        print("Usuario autenticado: ${user.uid}");

        // Save the token to Firestore under the user's document
        await _firestore.collection('users').doc(user.uid).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );

        print("Token guardado en Firestore con éxito.");
      } else {
        print("⚠️ No hay usuario autenticado. No se guardó el token.");
      }
    } else {
      print("⚠️ No se pudo obtener el token de FCM.");
    }
  }
}
