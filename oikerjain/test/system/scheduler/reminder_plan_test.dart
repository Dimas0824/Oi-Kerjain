import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';
import 'package:oikerjain/system/scheduler/reminder_plan.dart';

void main() {
  group('ReminderPlanBuilder', () {
    const planner = ReminderPlanBuilder();
    final now = DateTime(2026, 2, 15, 9);

    Task buildTask({
      required int dueAtEpochMillis,
      int? snoozedUntilEpochMillis,
    }) {
      return Task(
        id: 'task-1',
        title: 'Task',
        createdAtEpochMillis: DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
        dueAtEpochMillis: dueAtEpochMillis,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.medium,
        category: TaskCategory.work,
        isDone: false,
        completedAtEpochMillis: null,
        snoozedUntilEpochMillis: snoozedUntilEpochMillis,
        updatedAtEpochMillis: DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
      );
    }

    List<DateTime> toTimes(List<ReminderPlanEntry> entries) {
      return entries
          .map((entry) => DateTime.fromMillisecondsSinceEpoch(entry.scheduledAtEpochMillis))
          .toList();
    }

    test('uses daily cadence when deadline is more than 3 days away', () {
      final task = buildTask(
        dueAtEpochMillis: DateTime(2026, 2, 24, 9).millisecondsSinceEpoch,
      );

      final plan = planner.build(task: task, now: now);
      final times = toTimes(plan);

      expect(
        times,
        <DateTime>[
          DateTime(2026, 2, 16, 9),
          DateTime(2026, 2, 17, 9),
          DateTime(2026, 2, 18, 9),
        ],
      );
    });

    test('uses 12-hour cadence when deadline is within 3 days', () {
      final task = buildTask(
        dueAtEpochMillis: DateTime(2026, 2, 17, 21).millisecondsSinceEpoch,
      );

      final plan = planner.build(task: task, now: now);
      final times = toTimes(plan);

      expect(
        times,
        <DateTime>[
          DateTime(2026, 2, 15, 21),
          DateTime(2026, 2, 16, 9),
          DateTime(2026, 2, 16, 21),
          DateTime(2026, 2, 17, 9),
          DateTime(2026, 2, 17, 21),
        ],
      );
    });

    test('uses hourly cadence when deadline is on the same day', () {
      final task = buildTask(
        dueAtEpochMillis: DateTime(2026, 2, 15, 13).millisecondsSinceEpoch,
      );

      final plan = planner.build(task: task, now: now);
      final times = toTimes(plan);

      expect(
        times,
        <DateTime>[
          DateTime(2026, 2, 15, 10),
          DateTime(2026, 2, 15, 11),
          DateTime(2026, 2, 15, 12),
          DateTime(2026, 2, 15, 13),
        ],
      );
      expect(plan.every((entry) => entry.isCloseDeadline), isTrue);
    });

    test('limits reminders to 72-hour rolling window', () {
      final task = buildTask(
        dueAtEpochMillis: DateTime(2026, 2, 25, 9).millisecondsSinceEpoch,
      );

      final plan = planner.build(task: task, now: now);
      final times = toTimes(plan);

      expect(times.last, DateTime(2026, 2, 18, 9));
      expect(
        times.every((item) => item.isBefore(DateTime(2026, 2, 18, 9, 0, 1))),
        isTrue,
      );
    });

    test('applies snooze window and removes collided reminders', () {
      final task = buildTask(
        dueAtEpochMillis: DateTime(2026, 2, 15, 15).millisecondsSinceEpoch,
        snoozedUntilEpochMillis: DateTime(2026, 2, 15, 13).millisecondsSinceEpoch,
      );

      final plan = planner.build(task: task, now: now);
      final times = toTimes(plan);

      expect(
        times,
        <DateTime>[
          DateTime(2026, 2, 15, 13),
          DateTime(2026, 2, 15, 14),
          DateTime(2026, 2, 15, 15),
        ],
      );
    });
  });
}
