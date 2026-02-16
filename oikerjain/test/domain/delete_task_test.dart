import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/data/local/in_memory_task_store.dart';
import 'package:oikerjain/data/task_repository_impl.dart';
import 'package:oikerjain/domain/scheduler/reminder_scheduler.dart';
import 'package:oikerjain/domain/usecase/delete_task.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

import '../test_helpers.dart';

void main() {
  group('DeleteTaskUseCase', () {
    final clock = FixedClock(DateTime(2026, 2, 16, 10));

    test('still deletes task when scheduler cancel throws', () async {
      final sourceTask = Task(
        id: 'task-delete',
        title: 'Task Delete',
        createdAtEpochMillis: DateTime(2026, 2, 16, 9).millisecondsSinceEpoch,
        dueAtEpochMillis: DateTime(2026, 2, 16, 12).millisecondsSinceEpoch,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.medium,
        category: TaskCategory.work,
        isDone: false,
        completedAtEpochMillis: null,
        updatedAtEpochMillis: 1,
      );

      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: <Task>[sourceTask]),
        clock: clock,
      );
      final useCase = DeleteTaskUseCase(repository, _ThrowingScheduler());

      await useCase(sourceTask.id);
      final tasks = await repository.getTasks();
      final history = await repository.getHistoryTasks();

      expect(tasks, isEmpty);
      expect(history, isEmpty);
    });
  });
}

class _ThrowingScheduler implements ReminderScheduler {
  @override
  Future<void> cancel(String taskId) async {
    throw StateError('cancel failed');
  }

  @override
  Future<void> schedule(Task task) async {
    throw StateError('schedule failed');
  }

  @override
  Future<void> rescheduleAll(List<Task> tasks) async {
    throw StateError('reschedule failed');
  }
}
