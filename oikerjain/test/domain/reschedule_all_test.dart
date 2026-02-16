import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/data/local/in_memory_task_store.dart';
import 'package:oikerjain/data/task_repository_impl.dart';
import 'package:oikerjain/domain/scheduler/reminder_scheduler.dart';
import 'package:oikerjain/domain/usecase/compute_next_occurrence.dart';
import 'package:oikerjain/domain/usecase/reschedule_all.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

import '../test_helpers.dart';

void main() {
  test('rescheduleAll rolls overdue repeat tasks and skips overdue non-repeat', () async {
    final clock = FixedClock(DateTime(2026, 2, 15, 9, 0));
    final repeatOverdue = Task(
      id: 'repeat-overdue',
      title: 'Repeat Overdue',
      dueAtEpochMillis: DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
      repeatRule: RepeatRule.daily,
      priority: TaskPriority.high,
      category: TaskCategory.work,
      isDone: false,
      updatedAtEpochMillis: 1,
    );
    final nonRepeatOverdue = Task(
      id: 'non-repeat-overdue',
      title: 'Non Repeat Overdue',
      dueAtEpochMillis: DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
      repeatRule: RepeatRule.none,
      priority: TaskPriority.medium,
      category: TaskCategory.work,
      isDone: false,
      updatedAtEpochMillis: 1,
    );
    final futureTask = Task(
      id: 'future',
      title: 'Future',
      dueAtEpochMillis: DateTime(2026, 2, 16, 9).millisecondsSinceEpoch,
      repeatRule: RepeatRule.none,
      priority: TaskPriority.low,
      category: TaskCategory.personal,
      isDone: false,
      updatedAtEpochMillis: 1,
    );

    final repository = TaskRepositoryImpl(
      InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[repeatOverdue, nonRepeatOverdue, futureTask],
      ),
      clock: clock,
    );
    final scheduler = _RecordingScheduler();
    final useCase = RescheduleAllUseCase(
      repository,
      scheduler,
      const ComputeNextOccurrenceUseCase(),
      clock: clock,
    );

    await useCase.call();

    final tasks = await repository.getTasks();
    final updatedRepeat = tasks.singleWhere((task) => task.id == 'repeat-overdue');
    expect(
      DateTime.fromMillisecondsSinceEpoch(updatedRepeat.dueAtEpochMillis),
      DateTime(2026, 2, 16, 9),
    );

    expect(
      scheduler.lastRescheduled.map((task) => task.id).toList(),
      containsAll(<String>['repeat-overdue', 'future']),
    );
    expect(
      scheduler.lastRescheduled.map((task) => task.id),
      isNot(contains('non-repeat-overdue')),
    );
  });
}

class _RecordingScheduler implements ReminderScheduler {
  List<Task> lastRescheduled = <Task>[];

  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> rescheduleAll(List<Task> tasks) async {
    lastRescheduled = List<Task>.from(tasks);
  }

  @override
  Future<void> schedule(Task task) async {}
}
