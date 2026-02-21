import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/constants/notification_const.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings);

  final androidPlugin = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await androidPlugin?.createNotificationChannel(
    AndroidNotificationChannel(
      NotificationConst.channelId,
      NotificationConst.channelName,
      description: NotificationConst.channelDescription,
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(
        NotificationConst.androidSoundResourceName,
      ),
    ),
  );

  if (message.notification == null && message.data.isEmpty) {
    return;
  }

  final title =
      message.notification?.title ??
      message.data['title']?.toString() ??
      NotificationConst.channelName;
  final body =
      message.notification?.body ??
      message.data['body']?.toString() ??
      'Ada update tugas baru';

  await plugin.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationConst.channelId,
        NotificationConst.channelName,
        channelDescription: NotificationConst.channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound(
          NotificationConst.androidSoundResourceName,
        ),
      ),
    ),
    payload: message.data['taskId']?.toString(),
  );
}

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotificationsPlugin,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotificationsPlugin =
           localNotificationsPlugin ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      developer.log(
        'Notification opened from background',
        name: 'oikerjain.fcm',
        error: message.messageId,
      );
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      developer.log(
        'Notification opened from terminated state',
        name: 'oikerjain.fcm',
        error: initialMessage.messageId,
      );
    }

    final token = await _messaging.getToken();
    developer.log('FCM token: $token', name: 'oikerjain.fcm');

    _messaging.onTokenRefresh.listen(
      (newToken) => developer.log(
        'FCM token refreshed: $newToken',
        name: 'oikerjain.fcm',
      ),
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (message.notification == null && message.data.isEmpty) {
      return;
    }

    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        NotificationConst.channelName;
    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        'Ada update tugas baru';

    await _localNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationConst.channelId,
          NotificationConst.channelName,
          channelDescription: NotificationConst.channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(
            NotificationConst.androidSoundResourceName,
          ),
        ),
      ),
      payload: message.data['taskId']?.toString(),
    );
  }
}
