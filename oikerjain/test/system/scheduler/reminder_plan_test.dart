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
      required String id,
      required int dueAtEpochMillis,
      int? snoozedUntilEpochMillis,
      bool isDone = false,
    }) {
      return Task(
        id: id,
        title: id,
        createdAtEpochMillis: DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
        dueAtEpochMillis: dueAtEpochMillis,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.medium,
        category: TaskCategory.work,
        isDone: isDone,
        completedAtEpochMillis: null,
        snoozedUntilEpochMillis: snoozedUntilEpochMillis,
        updatedAtEpochMillis: DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
      );
    }

    DateTime toTime(ReminderPlanEntry entry) {
      return DateTime.fromMillisecondsSinceEpoch(entry.scheduledAtEpochMillis);
    }

    test('schedules close deadline reminder 1 hour before dueAt', () {
      final task = buildTask(
        id: 'task-close',
        dueAtEpochMillis: DateTime(2026, 2, 15, 12).millisecondsSinceEpoch,
      );

      final plan = planner.build(task: task, now: now);

      expect(toTime(plan.first), DateTime(2026, 2, 15, 11));
      expect(plan.first.kind, ReminderKind.closeDeadline);
      expect(toTime(plan[1]), DateTime(2026, 2, 15, 12));
      expect(plan[1].kind, ReminderKind.overdue);
    });

    test('schedules overdue reminders every 30 minutes after dueAt', () {
      final task = buildTask(
        id: 'task-overdue',
        dueAtEpochMillis: DateTime(2026, 2, 15, 10).millisecondsSinceEpoch,
      );

      final plan = planner.build(task: task, now: now);
      final overdue =
          plan
              .where((entry) => entry.kind == ReminderKind.overdue)
              .take(4)
              .map(toTime)
              .toList();

      expect(overdue, <DateTime>[
        DateTime(2026, 2, 15, 10),
        DateTime(2026, 2, 15, 10, 30),
        DateTime(2026, 2, 15, 11),
        DateTime(2026, 2, 15, 11, 30),
      ]);
    });

    test('adds catch-up close deadline reminder when now is inside 1-hour window', () {
      final task = buildTask(
        id: 'task-catch-up',
        dueAtEpochMillis: DateTime(2026, 2, 15, 9, 30).millisecondsSinceEpoch,
      );

      final plan = planner.build(task: task, now: now);

      expect(toTime(plan.first), DateTime(2026, 2, 15, 9, 1));
      expect(plan.first.kind, ReminderKind.closeDeadline);
      expect(toTime(plan[1]), DateTime(2026, 2, 15, 9, 30));
      expect(plan[1].kind, ReminderKind.overdue);
    });

    test('overdue reminders follow 30-minute cadence and skip past slots', () {
      final task = buildTask(
        id: 'task-overdue-offset',
        dueAtEpochMillis: DateTime(2026, 2, 15, 8, 45).millisecondsSinceEpoch,
      );

      final plan = planner.build(task: task, now: now);
      final firstThree = plan.take(3).map(toTime).toList();

      expect(firstThree, <DateTime>[
        DateTime(2026, 2, 15, 9, 15),
        DateTime(2026, 2, 15, 9, 45),
        DateTime(2026, 2, 15, 10, 15),
      ]);
      expect(plan.take(3).every((entry) => entry.kind == ReminderKind.overdue), isTrue);
    });

    test('respects snooze window for overdue reminders', () {
      final task = buildTask(
        id: 'task-snoozed',
        dueAtEpochMillis: DateTime(2026, 2, 15, 8, 30).millisecondsSinceEpoch,
        snoozedUntilEpochMillis: DateTime(
          2026,
          2,
          15,
          9,
          40,
        ).millisecondsSinceEpoch,
      );

      final plan = planner.build(task: task, now: now);

      expect(toTime(plan.first), DateTime(2026, 2, 15, 10, 0));
      expect(plan.first.kind, ReminderKind.overdue);
    });

    test('buildUpcomingSummary returns one summary for tasks due <= 3 days', () {
      final tasks = <Task>[
        buildTask(
          id: 'due-2d',
          dueAtEpochMillis: DateTime(2026, 2, 17, 9).millisecondsSinceEpoch,
        ),
        buildTask(
          id: 'due-2h',
          dueAtEpochMillis: DateTime(2026, 2, 15, 11).millisecondsSinceEpoch,
        ),
        buildTask(
          id: 'close-deadline',
          dueAtEpochMillis: DateTime(2026, 2, 15, 9, 30).millisecondsSinceEpoch,
        ),
        buildTask(
          id: 'outside-window',
          dueAtEpochMillis: DateTime(2026, 2, 20, 9).millisecondsSinceEpoch,
        ),
        buildTask(
          id: 'snoozed',
          dueAtEpochMillis: DateTime(2026, 2, 16, 9).millisecondsSinceEpoch,
          snoozedUntilEpochMillis: DateTime(
            2026,
            2,
            15,
            10,
          ).millisecondsSinceEpoch,
        ),
        buildTask(
          id: 'done',
          dueAtEpochMillis: DateTime(2026, 2, 16, 9).millisecondsSinceEpoch,
          isDone: true,
        ),
      ];

      final summary = planner.buildUpcomingSummary(tasks: tasks, now: now);

      expect(summary, isNotNull);
      expect(
        DateTime.fromMillisecondsSinceEpoch(summary!.scheduledAtEpochMillis),
        DateTime(2026, 2, 15, 9, 1),
      );
      expect(summary.taskIds, <String>['due-2h', 'due-2d']);
    });

    test('buildUpcomingSummary returns null when no eligible tasks', () {
      final tasks = <Task>[
        buildTask(
          id: 'close',
          dueAtEpochMillis: DateTime(2026, 2, 15, 9, 10).millisecondsSinceEpoch,
        ),
        buildTask(
          id: 'outside',
          dueAtEpochMillis: DateTime(2026, 2, 20, 9).millisecondsSinceEpoch,
        ),
      ];

      final summary = planner.buildUpcomingSummary(tasks: tasks, now: now);

      expect(summary, isNull);
    });
  });
}
