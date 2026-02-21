import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';
import 'package:oikerjain/system/notification/notification_factory.dart';
import 'package:oikerjain/system/scheduler/reminder_plan.dart';

void main() {
  group('NotificationFactory', () {
    const factory = NotificationFactory();

    Task createTask() {
      return Task(
        id: 'task-1',
        title: 'System Architecture',
        description: 'Define service boundaries',
        createdAtEpochMillis: DateTime(2026, 2, 15, 9).millisecondsSinceEpoch,
        dueAtEpochMillis: DateTime(2026, 2, 15, 10).millisecondsSinceEpoch,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.high,
        category: TaskCategory.work,
        isDone: false,
        completedAtEpochMillis: null,
        updatedAtEpochMillis: DateTime(2026, 2, 15, 9).millisecondsSinceEpoch,
      );
    }

    test('builds title with priority prefix', () {
      final title = factory.buildTitle(createTask());
      expect(title, '[TINGGI] System Architecture');
    });

    test('buildBody close deadline uses dynamic remaining time', () {
      final task = createTask().copyWith(
        dueAtEpochMillis: DateTime(2026, 2, 15, 17, 4).millisecondsSinceEpoch,
      );

      final body = factory.buildBody(
        task,
        reminderKind: ReminderKind.closeDeadline,
        scheduledAtEpochMillis: DateTime(
          2026,
          2,
          15,
          17,
          0,
        ).millisecondsSinceEpoch,
      );

      expect(body, contains('4 menit lagi'));
    });

    test(
      'buildBody close deadline falls back to 1 hour for standard schedule',
      () {
        final body = factory.buildBody(
          createTask(),
          reminderKind: ReminderKind.closeDeadline,
        );

        expect(body, contains('1 jam lagi'));
      },
    );

    test('encodes and decodes payload with reminder kind', () {
      final payload = factory.buildPayload(
        createTask(),
        scheduledAtEpochMillis: DateTime(
          2026,
          2,
          15,
          9,
          30,
        ).millisecondsSinceEpoch,
        reminderKind: ReminderKind.closeDeadline,
      );
      final taskId = factory.taskIdFromPayload(payload);
      final parsed = factory.parsePayload(payload);

      expect(taskId, 'task-1');
      expect(
        parsed?.scheduledAtEpochMillis,
        DateTime(2026, 2, 15, 9, 30).millisecondsSinceEpoch,
      );
      expect(parsed?.reminderKind, ReminderKind.closeDeadline);
      expect(parsed?.isCloseDeadline, isTrue);
    });

    test('returns null when payload is malformed', () {
      expect(factory.taskIdFromPayload('{bad'), isNull);
      expect(factory.taskIdFromPayload(null), isNull);
    });

    test('supports legacy payload with only taskId', () {
      const legacyPayload = '{"taskId":"task-legacy"}';
      final parsed = factory.parsePayload(legacyPayload);

      expect(parsed?.taskId, 'task-legacy');
      expect(parsed?.scheduledAtEpochMillis, isNull);
      expect(parsed?.reminderKind, isNull);
      expect(parsed?.isCloseDeadline, isFalse);
    });

    test('supports summary payload with task ids', () {
      final payload = factory.buildUpcomingSummaryPayload(
        scheduledAtEpochMillis: DateTime(
          2026,
          2,
          15,
          9,
          1,
        ).millisecondsSinceEpoch,
        taskIds: const <String>['task-1', 'task-2'],
      );
      final parsed = factory.parsePayload(payload);

      expect(parsed?.taskId, isNull);
      expect(parsed?.summaryTaskIds, <String>['task-1', 'task-2']);
      expect(
        parsed?.scheduledAtEpochMillis,
        DateTime(2026, 2, 15, 9, 1).millisecondsSinceEpoch,
      );
    });
  });
}
