import 'dart:math' as math;

import '../../model/task.dart';

class ReminderPlanBuilder {
  const ReminderPlanBuilder({
    Duration rollingWindow = const Duration(hours: 72),
    Duration urgentWindow = const Duration(hours: 1),
    Duration catchUpLead = const Duration(minutes: 1),
  }) : _rollingWindow = rollingWindow,
       _urgentWindow = urgentWindow,
       _catchUpLead = catchUpLead;

  final Duration _rollingWindow;
  final Duration _urgentWindow;
  final Duration _catchUpLead;

  List<ReminderPlanEntry> build({
    required Task task,
    required DateTime now,
  }) {
    final nowMillis = now.millisecondsSinceEpoch;
    if (task.isDone) {
      return const <ReminderPlanEntry>[];
    }

    final dueAtEpochMillis = task.dueAtEpochMillis;
    if (dueAtEpochMillis <= nowMillis) {
      final snoozedUntil = task.snoozedUntilEpochMillis;
      return <ReminderPlanEntry>[
        ReminderPlanEntry(
          scheduledAtEpochMillis: snoozedUntil != null && snoozedUntil > nowMillis
              ? snoozedUntil
              : nowMillis + _catchUpLead.inMilliseconds,
          isCloseDeadline: true,
        ),
      ];
    }

    final windowEndMillis = math.min(
      dueAtEpochMillis,
      nowMillis + _rollingWindow.inMilliseconds,
    );
    final reminderEpochs = <int>{};
    var cursorMillis = nowMillis;

    while (true) {
      final nextReminder = _nextReminderEpochMillis(
        cursorEpochMillis: cursorMillis,
        dueAtEpochMillis: dueAtEpochMillis,
      );
      if (nextReminder > windowEndMillis) {
        break;
      }
      reminderEpochs.add(nextReminder);
      cursorMillis = nextReminder;
      if (cursorMillis >= dueAtEpochMillis) {
        break;
      }
    }

    reminderEpochs.add(dueAtEpochMillis);
    _applySnoozeWindow(
      reminderEpochs: reminderEpochs,
      task: task,
      nowMillis: nowMillis,
      windowEndMillis: windowEndMillis,
    );
    if (_shouldAddCatchUpReminder(task: task, nowMillis: nowMillis)) {
      reminderEpochs.add(
        math.min(
          nowMillis + _catchUpLead.inMilliseconds,
          dueAtEpochMillis,
        ),
      );
    }

    final sorted = reminderEpochs
        .where((epoch) => epoch > nowMillis && epoch <= windowEndMillis)
        .toList()
      ..sort();

    return sorted
        .map(
          (scheduledAtEpochMillis) => ReminderPlanEntry(
            scheduledAtEpochMillis: scheduledAtEpochMillis,
            isCloseDeadline: _isCloseDeadline(
              scheduledAtEpochMillis: scheduledAtEpochMillis,
              dueAtEpochMillis: dueAtEpochMillis,
            ),
          ),
        )
        .toList();
  }

  int _nextReminderEpochMillis({
    required int cursorEpochMillis,
    required int dueAtEpochMillis,
  }) {
    final remaining = Duration(
      milliseconds: dueAtEpochMillis - cursorEpochMillis,
    );

    if (remaining <= const Duration(days: 1) ||
        _isSameLocalDay(
          cursorEpochMillis: cursorEpochMillis,
          dueAtEpochMillis: dueAtEpochMillis,
        )) {
      return cursorEpochMillis + const Duration(hours: 1).inMilliseconds;
    }

    if (remaining <= const Duration(days: 3)) {
      return cursorEpochMillis + const Duration(hours: 12).inMilliseconds;
    }

    return cursorEpochMillis + const Duration(days: 1).inMilliseconds;
  }

  void _applySnoozeWindow({
    required Set<int> reminderEpochs,
    required Task task,
    required int nowMillis,
    required int windowEndMillis,
  }) {
    final snoozedUntil = task.snoozedUntilEpochMillis;
    if (snoozedUntil == null || snoozedUntil <= nowMillis) {
      return;
    }

    final snoozedAt = math.min(snoozedUntil, task.dueAtEpochMillis);
    reminderEpochs.removeWhere((epoch) => epoch < snoozedAt);
    if (snoozedAt <= windowEndMillis) {
      reminderEpochs.add(snoozedAt);
    }
  }

  bool _isCloseDeadline({
    required int scheduledAtEpochMillis,
    required int dueAtEpochMillis,
  }) {
    final remaining = Duration(
      milliseconds: dueAtEpochMillis - scheduledAtEpochMillis,
    );
    return remaining <= const Duration(days: 1) ||
        _isSameLocalDay(
          cursorEpochMillis: scheduledAtEpochMillis,
          dueAtEpochMillis: dueAtEpochMillis,
        );
  }

  bool _shouldAddCatchUpReminder({
    required Task task,
    required int nowMillis,
  }) {
    final snoozedUntil = task.snoozedUntilEpochMillis;
    if (snoozedUntil != null && snoozedUntil > nowMillis) {
      return false;
    }

    final remaining = Duration(
      milliseconds: task.dueAtEpochMillis - nowMillis,
    );
    return remaining <= _urgentWindow;
  }

  bool _isSameLocalDay({
    required int cursorEpochMillis,
    required int dueAtEpochMillis,
  }) {
    final cursor = DateTime.fromMillisecondsSinceEpoch(cursorEpochMillis);
    final dueAt = DateTime.fromMillisecondsSinceEpoch(dueAtEpochMillis);
    return cursor.year == dueAt.year &&
        cursor.month == dueAt.month &&
        cursor.day == dueAt.day;
  }
}

class ReminderPlanEntry {
  const ReminderPlanEntry({
    required this.scheduledAtEpochMillis,
    required this.isCloseDeadline,
  });

  final int scheduledAtEpochMillis;
  final bool isCloseDeadline;
}
