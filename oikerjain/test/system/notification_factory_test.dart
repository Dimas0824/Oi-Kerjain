import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';
import 'package:oikerjain/system/notification/notification_factory.dart';

void main() {
  group('NotificationFactory', () {
    const factory = NotificationFactory();

    Task createTask() {
      return Task(
        id: 'task-1',
        title: 'System Architecture',
        description: 'Define service boundaries',
        createdAtEpochMillis:
            DateTime(2026, 2, 15, 9).millisecondsSinceEpoch,
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

    test('encodes and decodes taskId from payload', () {
      final payload = factory.buildPayload(createTask());
      final taskId = factory.taskIdFromPayload(payload);

      expect(taskId, 'task-1');
    });

    test('returns null when payload is malformed', () {
      expect(factory.taskIdFromPayload('{bad'), isNull);
      expect(factory.taskIdFromPayload(null), isNull);
    });
  });
}
