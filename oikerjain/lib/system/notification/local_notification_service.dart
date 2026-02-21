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
        _notificationFactory.buildBody(
          task,
          reminderKind: reminder.kind,
          scheduledAtEpochMillis: reminder.scheduledAtEpochMillis,
        ),
        when,
        _buildNotificationDetails(reminderKind: reminder.kind),
        payload: _notificationFactory.buildPayload(
          task,
          scheduledAtEpochMillis: reminder.scheduledAtEpochMillis,
          reminderKind: reminder.kind,
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: _androidScheduleMode,
      );
    }
  }

  Future<void> scheduleUpcomingSummary({
    required List<Task> tasks,
    required UpcomingSummaryPlan? plan,
  }) async {
    await _plugin.cancel(NotificationConst.upcomingSummaryNotificationId);
    if (plan == null || plan.taskIds.isEmpty) {
      return;
    }

    final tasksById = <String, Task>{for (final task in tasks) task.id: task};
    final summaryTasks = <Task>[];
    for (final taskId in plan.taskIds) {
      final task = tasksById[taskId];
      if (task != null && !task.isDone) {
        summaryTasks.add(task);
      }
    }
    if (summaryTasks.isEmpty) {
      return;
    }

    final when = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.local,
      plan.scheduledAtEpochMillis,
    );
    final now = tz.TZDateTime.now(tz.local);
    if (!when.isAfter(now)) {
      return;
    }

    await _plugin.zonedSchedule(
      NotificationConst.upcomingSummaryNotificationId,
      _notificationFactory.buildUpcomingSummaryTitle(summaryTasks.length),
      _notificationFactory.buildUpcomingSummaryBody(summaryTasks),
      when,
      _buildNotificationDetails(isSummary: true),
      payload: _notificationFactory.buildUpcomingSummaryPayload(
        scheduledAtEpochMillis: plan.scheduledAtEpochMillis,
        taskIds: summaryTasks.map((task) => task.id).toList(growable: false),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: _androidScheduleMode,
    );
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

  NotificationDetails _buildNotificationDetails({
    ReminderKind? reminderKind,
    bool isSummary = false,
  }) {
    final includeTaskActions = !isSummary && reminderKind != null;
    final androidActions = includeTaskActions
        ? _taskReminderAndroidActions()
        : const <AndroidNotificationAction>[];

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
        actions: includeTaskActions ? androidActions : null,
      ),
      iOS: DarwinNotificationDetails(
        sound: NotificationConst.iosSoundFileName,
        categoryIdentifier: includeTaskActions
            ? NotificationConst.iosTaskReminderCategoryId
            : NotificationConst.iosSummaryCategoryId,
      ),
    );
  }

  List<AndroidNotificationAction> _taskReminderAndroidActions() {
    return const <AndroidNotificationAction>[
      AndroidNotificationAction(
        NotificationConst.actionDone,
        'DONE',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        NotificationConst.actionSnooze10m,
        'SNOOZE 10M',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        NotificationConst.actionSnooze30m,
        'SNOOZE 30M',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        NotificationConst.actionSnooze60m,
        'SNOOZE 60M',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        NotificationConst.actionSnoozeCustom,
        'SNOOZE CUSTOM',
        showsUserInterface: true,
      ),
    ];
  }

  List<DarwinNotificationCategory> _darwinNotificationCategories() {
    return <DarwinNotificationCategory>[
      DarwinNotificationCategory(NotificationConst.iosSummaryCategoryId),
      DarwinNotificationCategory(
        NotificationConst.iosTaskReminderCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(
            NotificationConst.actionDone,
            'DONE',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            NotificationConst.actionSnooze10m,
            'SNOOZE 10M',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            NotificationConst.actionSnooze30m,
            'SNOOZE 30M',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            NotificationConst.actionSnooze60m,
            'SNOOZE 60M',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.foreground,
            },
          ),
          DarwinNotificationAction.plain(
            NotificationConst.actionSnoozeCustom,
            'SNOOZE CUSTOM',
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
