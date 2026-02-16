import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/notification_const.dart';
import '../../model/task.dart';
import '../scheduler/reminder_plan.dart';
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
  AndroidScheduleMode _androidScheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle;

  Future<void> init({required NotificationActionCallback onAction}) async {
    _actionCallback = onAction;
    tzdata.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: _darwinNotificationCategories(),
    );
    final settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
    await _configureAndroidScheduleMode(androidPlugin);
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
  }

  Future<void> scheduleTaskReminders(
    Task task,
    List<ReminderPlanEntry> reminders,
  ) async {
    await cancelTask(task.id);
    if (task.isDone || reminders.isEmpty) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    for (final reminder in reminders) {
      final when = tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.local,
        reminder.scheduledAtEpochMillis,
      );
      if (!when.isAfter(now)) {
        continue;
      }

      await _plugin.zonedSchedule(
        _notificationId(task.id, reminder.scheduledAtEpochMillis),
        _notificationFactory.buildTitle(task),
        _notificationFactory.buildBody(task),
        when,
        _buildNotificationDetails(reminder.isCloseDeadline),
        payload: _notificationFactory.buildPayload(
          task,
          scheduledAtEpochMillis: reminder.scheduledAtEpochMillis,
          isCloseDeadline: reminder.isCloseDeadline,
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: _androidScheduleMode,
      );
    }
  }

  Future<void> cancelTask(String taskId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final requestTaskId = _notificationFactory.taskIdFromPayload(
        request.payload,
      );
      if (requestTaskId == taskId) {
        await _plugin.cancel(request.id);
      }
    }

    await _plugin.cancel(_legacyNotificationId(taskId));
  }

  Future<void> _onDidReceiveNotificationResponse(
    NotificationResponse response,
  ) async {
    final taskId = _notificationFactory.taskIdFromPayload(response.payload);
    await _actionCallback?.call(taskId: taskId, actionId: response.actionId);
  }

  NotificationDetails _buildNotificationDetails(bool isCloseDeadline) {
    final androidActions = isCloseDeadline
        ? _closeDeadlineAndroidActions()
        : _defaultAndroidActions();

    return NotificationDetails(
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
        actions: androidActions,
      ),
      iOS: DarwinNotificationDetails(
        sound: NotificationConst.iosSoundFileName,
        categoryIdentifier: isCloseDeadline
            ? NotificationConst.iosCloseDeadlineCategoryId
            : NotificationConst.iosDefaultCategoryId,
      ),
    );
  }

  List<AndroidNotificationAction> _defaultAndroidActions() {
    return const <AndroidNotificationAction>[
      AndroidNotificationAction(
        NotificationConst.actionDone,
        'DONE',
        showsUserInterface: true,
      ),
    ];
  }

  List<AndroidNotificationAction> _closeDeadlineAndroidActions() {
    return const <AndroidNotificationAction>[
      AndroidNotificationAction(
        NotificationConst.actionSnooze1h,
        'SNOOZE 1H',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        NotificationConst.actionSnooze2h,
        'SNOOZE 2H',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        NotificationConst.actionSnooze4h,
        'SNOOZE 4H',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        NotificationConst.actionSnoozeCustom,
        'SNOOZE +1H',
        showsUserInterface: true,
      ),
    ];
  }

  List<DarwinNotificationCategory> _darwinNotificationCategories() {
    return <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        NotificationConst.iosDefaultCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            NotificationConst.actionDone,
            'DONE',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),
      DarwinNotificationCategory(
        NotificationConst.iosCloseDeadlineCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            NotificationConst.actionSnooze1h,
            'SNOOZE 1H',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            NotificationConst.actionSnooze2h,
            'SNOOZE 2H',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            NotificationConst.actionSnooze4h,
            'SNOOZE 4H',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            NotificationConst.actionSnoozeCustom,
            'SNOOZE +1H',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
        ],
      ),
    ];
  }

  int _notificationId(String taskId, int scheduledAtEpochMillis) =>
      Object.hash(taskId, scheduledAtEpochMillis) & 0x7fffffff;

  int _legacyNotificationId(String taskId) => taskId.hashCode & 0x7fffffff;

  Future<void> _configureAndroidScheduleMode(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    if (androidPlugin == null) {
      return;
    }

    var canScheduleExact =
        await androidPlugin.canScheduleExactNotifications() ?? false;
    if (!canScheduleExact) {
      await androidPlugin.requestExactAlarmsPermission();
      canScheduleExact =
          await androidPlugin.canScheduleExactNotifications() ?? false;
    }

    _androidScheduleMode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (error, stackTrace) {
      developer.log(
        'Failed to configure local timezone, fallback to UTC',
        name: 'oikerjain.notifications',
        error: error,
        stackTrace: stackTrace,
      );
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }
}
