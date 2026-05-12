import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Message reçu en arrière-plan: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Les notifications push ne fonctionnent pas sur Web en debug
    // Elles fonctionneront sur Android et iOS
    if (kIsWeb) {
      debugPrint('Notifications: mode Web — FCM limité sur navigateur');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Message reçu: ${message.notification?.title}');
    });

    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Sur Web on affiche juste un log
    // Sur mobile les vraies notifications seront envoyées via FCM depuis les Cloud Functions
    debugPrint('Notification: $title — $body');
  }

  Future<String?> getToken() async {
    if (kIsWeb) return null;
    return await _messaging.getToken();
  }
}