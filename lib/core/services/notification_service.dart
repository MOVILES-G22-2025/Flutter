import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Service to handle local notifications in the app
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // Initialize notification settings for Android and iOS
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  // Show a reminder notification for pending products
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
      'You have pending products',
      'Do not forget to complete them and upload their images',
      notification,
    );
  }
}