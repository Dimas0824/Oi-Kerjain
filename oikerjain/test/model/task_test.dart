import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

void main() {
  group('Task', () {
    test('json roundtrip preserves createdAt and completedAt', () {
      final source = Task(
        id: 'task-1',
        title: 'Task One',
        description: 'Desc',
        createdAtEpochMillis: DateTime(2026, 2, 10, 8).millisecondsSinceEpoch,
        dueAtEpochMillis: DateTime(2026, 2, 11, 9).millisecondsSinceEpoch,
        repeatRule: RepeatRule.weekly,
        priority: TaskPriority.high,
        category: TaskCategory.personal,
        isDone: true,
        completedAtEpochMillis: DateTime(2026, 2, 12, 10).millisecondsSinceEpoch,
        updatedAtEpochMillis: DateTime(2026, 2, 12, 10).millisecondsSinceEpoch,
      );

      final decoded = Task.fromJson(source.toJson());

      expect(decoded.id, source.id);
      expect(decoded.createdAtEpochMillis, source.createdAtEpochMillis);
      expect(decoded.completedAtEpochMillis, source.completedAtEpochMillis);
    });

    test('fromJson falls back to updatedAt for legacy payload', () {
      final updatedAt = DateTime(2026, 2, 15, 9).millisecondsSinceEpoch;
      final payload = <String, dynamic>{
        'id': 'legacy',
        'title': 'Legacy Task',
        'description': '',
        'dueAtEpochMillis': DateTime(2026, 2, 16, 10).millisecondsSinceEpoch,
        'repeatRule': 'none',
        'priority': 'medium',
        'category': 'work',
        'isDone': true,
        'updatedAtEpochMillis': updatedAt,
      };

      final task = Task.fromJson(payload);

      expect(task.createdAtEpochMillis, updatedAt);
      expect(task.completedAtEpochMillis, updatedAt);
    });
  });
}
