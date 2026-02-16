import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/notification_const.dart';
import '../../model/task.dart';
import 'notification_factory.dart';

typedef NotificationActionCallback =
    Future<void> Function({required String? taskId, required String? actionId});

class LocalNotificationService {
  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    NotificationFactory? notificationFactory,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _notificationFactory =
           notificationFactory ?? const NotificationFactory();

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationFactory _notificationFactory;
  NotificationActionCallback? _actionCallback;

  Future<void> init({required NotificationActionCallback onAction}) async {
    _actionCallback = onAction;
    tzdata.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConst.channelId,
        NotificationConst.channelName,
        description: NotificationConst.channelDescription,
        importance: Importance.max,
      ),
    );
  }

  Future<void> scheduleTask(Task task) async {
    final when = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.local,
      task.dueAtEpochMillis,
    );

    if (when.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationConst.channelId,
        NotificationConst.channelName,
        channelDescription: NotificationConst.channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(NotificationConst.actionDone, 'DONE'),
          const AndroidNotificationAction(
            NotificationConst.actionSnooze10m,
            'SNOOZE 10M',
          ),
        ],
      ),
    );

    await _plugin.zonedSchedule(
      _notificationId(task.id),
      _notificationFactory.buildTitle(task),
      _notificationFactory.buildBody(task),
      when,
      details,
      payload: _notificationFactory.buildPayload(task),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTask(String taskId) async {
    await _plugin.cancel(_notificationId(taskId));
  }

  Future<void> _onDidReceiveNotificationResponse(
    NotificationResponse response,
  ) async {
    final taskId = _notificationFactory.taskIdFromPayload(response.payload);
    await _actionCallback?.call(taskId: taskId, actionId: response.actionId);
  }

  int _notificationId(String taskId) => taskId.hashCode & 0x7fffffff;

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }
}
