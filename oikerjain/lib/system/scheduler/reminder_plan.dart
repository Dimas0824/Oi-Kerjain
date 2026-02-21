import 'dart:math' as math;

import '../../model/task.dart';

class ReminderPlanBuilder {
  const ReminderPlanBuilder({
    Duration rollingWindow = const Duration(hours: 72),
    Duration closeDeadlineLead = const Duration(hours: 1),
    Duration overdueCadence = const Duration(minutes: 30),
    Duration catchUpLead = const Duration(minutes: 1),
  }) : _rollingWindow = rollingWindow,
       _closeDeadlineLead = closeDeadlineLead,
       _overdueCadence = overdueCadence,
       _catchUpLead = catchUpLead;

  final Duration _rollingWindow;
  final Duration _closeDeadlineLead;
  final Duration _overdueCadence;
  final Duration _catchUpLead;

  List<ReminderPlanEntry> build({required Task task, required DateTime now}) {
    final nowMillis = now.millisecondsSinceEpoch;
    if (task.isDone) {
      return const <ReminderPlanEntry>[];
    }

    final dueAtEpochMillis = task.dueAtEpochMillis;
    final windowEndMillis = nowMillis + _rollingWindow.inMilliseconds;
    final snoozedUntil = task.snoozedUntilEpochMillis;
    final notBeforeMillis = math.max(
      nowMillis + _catchUpLead.inMilliseconds,
      snoozedUntil != null && snoozedUntil > nowMillis ? snoozedUntil : 0,
    );
    final remindersByEpoch = <int, ReminderKind>{};

    if (dueAtEpochMillis > nowMillis) {
      final closeReminderAt =
          dueAtEpochMillis - _closeDeadlineLead.inMilliseconds;
      final scheduledCloseReminder = math.max(
        closeReminderAt > nowMillis
            ? closeReminderAt
            : nowMillis + _catchUpLead.inMilliseconds,
        notBeforeMillis,
      );

      if (scheduledCloseReminder < dueAtEpochMillis &&
          scheduledCloseReminder <= windowEndMillis) {
        remindersByEpoch[scheduledCloseReminder] = ReminderKind.closeDeadline;
      }
    }

    if (dueAtEpochMillis <= windowEndMillis) {
      final firstOverdueReminder = _resolveFirstOverdueEpochMillis(
        dueAtEpochMillis: dueAtEpochMillis,
        minEpochMillis: notBeforeMillis,
      );

      for (
        var cursorMillis = firstOverdueReminder;
        cursorMillis <= windowEndMillis;
        cursorMillis += _overdueCadence.inMilliseconds
      ) {
        remindersByEpoch[cursorMillis] = ReminderKind.overdue;
      }
    }

    final sorted =
        remindersByEpoch.keys
            .where((epoch) => epoch > nowMillis)
            .toList()
          ..sort();

    return sorted
        .map(
          (scheduledAtEpochMillis) => ReminderPlanEntry(
            scheduledAtEpochMillis: scheduledAtEpochMillis,
            kind: remindersByEpoch[scheduledAtEpochMillis]!,
          ),
        )
        .toList();
  }

  UpcomingSummaryPlan? buildUpcomingSummary({
    required List<Task> tasks,
    required DateTime now,
  }) {
    final nowMillis = now.millisecondsSinceEpoch;
    final closeDeadlineBoundary =
        nowMillis + _closeDeadlineLead.inMilliseconds;
    final summaryWindowEnd = nowMillis + _rollingWindow.inMilliseconds;

    final eligibleTasks =
        tasks.where((task) {
            if (task.isDone) {
              return false;
            }

            if (task.dueAtEpochMillis <= closeDeadlineBoundary ||
                task.dueAtEpochMillis > summaryWindowEnd) {
              return false;
            }

            final snoozedUntil = task.snoozedUntilEpochMillis;
            if (snoozedUntil != null && snoozedUntil > nowMillis) {
              return false;
            }

            return true;
          }).toList()
          ..sort((a, b) => a.dueAtEpochMillis.compareTo(b.dueAtEpochMillis));

    if (eligibleTasks.isEmpty) {
      return null;
    }

    return UpcomingSummaryPlan(
      scheduledAtEpochMillis: nowMillis + _catchUpLead.inMilliseconds,
      taskIds: eligibleTasks.map((task) => task.id).toList(growable: false),
    );
  }

  int _resolveFirstOverdueEpochMillis({
    required int dueAtEpochMillis,
    required int minEpochMillis,
  }) {
    if (minEpochMillis <= dueAtEpochMillis) {
      return dueAtEpochMillis;
    }

    final intervalMillis = _overdueCadence.inMilliseconds;
    final elapsedSinceDue = minEpochMillis - dueAtEpochMillis;
    final ticksSinceDue = (elapsedSinceDue + intervalMillis - 1) ~/ intervalMillis;
    return dueAtEpochMillis + (ticksSinceDue * intervalMillis);
  }
}

enum ReminderKind { closeDeadline, overdue }

class ReminderPlanEntry {
  const ReminderPlanEntry({
    required this.scheduledAtEpochMillis,
    required this.kind,
  });

  final int scheduledAtEpochMillis;
  final ReminderKind kind;

  bool get isCloseDeadline => kind == ReminderKind.closeDeadline;

  bool get isOverdue => kind == ReminderKind.overdue;
}

class UpcomingSummaryPlan {
  const UpcomingSummaryPlan({
    required this.scheduledAtEpochMillis,
    required this.taskIds,
  });

  final int scheduledAtEpochMillis;
  final List<String> taskIds;
}
