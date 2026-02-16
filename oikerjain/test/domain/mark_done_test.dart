import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/data/local/in_memory_task_store.dart';
import 'package:oikerjain/data/task_repository_impl.dart';
import 'package:oikerjain/domain/scheduler/reminder_scheduler.dart';
import 'package:oikerjain/domain/usecase/mark_done.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

import '../test_helpers.dart';

void main() {
  group('MarkDoneUseCase', () {
    final clock = FixedClock(DateTime(2026, 2, 16, 10));

    test('still marks done when scheduler cancel throws', () async {
      final sourceTask = Task(
        id: 'task-mark-done',
        title: 'Task Mark Done',
        dueAtEpochMillis: DateTime(2026, 2, 16, 12).millisecondsSinceEpoch,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.medium,
        category: TaskCategory.work,
        isDone: false,
        updatedAtEpochMillis: 1,
      );

      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: <Task>[sourceTask]),
        clock: clock,
      );
      final useCase = MarkDoneUseCase(repository, _ThrowingScheduler());

      await useCase(sourceTask, isDone: true);
      final tasks = await repository.getTasks();

      expect(tasks.single.isDone, isTrue);
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
