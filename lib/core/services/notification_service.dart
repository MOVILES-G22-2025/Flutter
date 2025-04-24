import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> showReminderNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'drafts_channel',
      'Draft Products',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notification = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'Tienes productos pendientes',
      'No olvides completarlos y subir sus imágenes',
      notification,
    );
  }
}