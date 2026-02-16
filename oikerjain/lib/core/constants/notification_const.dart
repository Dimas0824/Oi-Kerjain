class NotificationConst {
  const NotificationConst._();

  static const String channelId = 'oikerjain_reminders_v2';
  static const String channelName = 'Task Reminders';
  static const String channelDescription = 'Scheduled reminders for Oi!Kerjain tasks';

  static const String androidSoundResourceName = 'notif_1';
  static const String iosSoundFileName = 'notif_1.mp3';

  static const String actionDone = 'DONE';
  static const String actionSnooze10mLegacy = 'SNOOZE_10M';
  static const String actionSnooze1h = 'SNOOZE_1H';
  static const String actionSnooze2h = 'SNOOZE_2H';
  static const String actionSnooze4h = 'SNOOZE_4H';
  static const String actionSnoozeCustom = 'SNOOZE_CUSTOM';

  static const String iosDefaultCategoryId = 'TASK_REMINDER_DEFAULT';
  static const String iosCloseDeadlineCategoryId = 'TASK_REMINDER_CLOSE';
}
