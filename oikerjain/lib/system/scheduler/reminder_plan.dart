import 'dart:math' as math;

import '../../model/task.dart';

class ReminderPlanBuilder {
  const ReminderPlanBuilder({
    Duration rollingWindow = const Duration(hours: 72),
  }) : _rollingWindow = rollingWindow;

  final Duration _rollingWindow;

  List<ReminderPlanEntry> build({
    required Task task,
    required DateTime now,
  }) {
    final nowMillis = now.millisecondsSinceEpoch;
    if (task.isDone || task.dueAtEpochMillis <= nowMillis) {
      return const <ReminderPlanEntry>[];
    }

    final windowEndMillis = math.min(
      task.dueAtEpochMillis,
      nowMillis + _rollingWindow.inMilliseconds,
    );
    final reminderEpochs = <int>{};
    var cursorMillis = nowMillis;

    while (true) {
      final nextReminder = _nextReminderEpochMillis(
        cursorEpochMillis: cursorMillis,
        dueAtEpochMillis: task.dueAtEpochMillis,
      );
      if (nextReminder > windowEndMillis) {
        break;
      }
      reminderEpochs.add(nextReminder);
      cursorMillis = nextReminder;
      if (cursorMillis >= task.dueAtEpochMillis) {
        break;
      }
    }

    reminderEpochs.add(task.dueAtEpochMillis);
    _applySnoozeWindow(
      reminderEpochs: reminderEpochs,
      task: task,
      nowMillis: nowMillis,
      windowEndMillis: windowEndMillis,
    );

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
              dueAtEpochMillis: task.dueAtEpochMillis,
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
