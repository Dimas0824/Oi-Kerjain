class NotificationConst {
  const NotificationConst._();

  static const String channelId = 'oikerjain_reminders_v2';
  static const String channelName = 'Task Reminders';
  static const String channelDescription =
      'Scheduled reminders for Oi!Kerjain tasks';

  static const int upcomingSummaryNotificationId = 94872921;

  static const String androidSoundResourceName = 'notif_1';
  static const String iosSoundFileName = 'notif_1.mp3';

  static const String actionDone = 'DONE';
  static const String actionSnooze10m = 'SNOOZE_10M';
  static const String actionSnooze30m = 'SNOOZE_30M';
  static const String actionSnooze60m = 'SNOOZE_60M';
  static const String actionSnoozeCustom = 'SNOOZE_CUSTOM';

  static const String actionSnooze10mLegacy = actionSnooze10m;
  static const String actionSnooze1hLegacy = 'SNOOZE_1H';
  static const String actionSnooze2hLegacy = 'SNOOZE_2H';
  static const String actionSnooze4hLegacy = 'SNOOZE_4H';

  static const String iosTaskReminderCategoryId = 'TASK_REMINDER_TASK';
  static const String iosSummaryCategoryId = 'TASK_REMINDER_SUMMARY';

  static const String iosDefaultCategoryId = iosSummaryCategoryId;
  static const String iosCloseDeadlineCategoryId = iosTaskReminderCategoryId;
}
