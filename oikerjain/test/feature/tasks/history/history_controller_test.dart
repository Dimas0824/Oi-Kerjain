import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/data/local/in_memory_task_store.dart';
import 'package:oikerjain/data/task_repository_impl.dart';
import 'package:oikerjain/domain/usecase/delete_task.dart';
import 'package:oikerjain/domain/usecase/get_history_tasks.dart';
import 'package:oikerjain/domain/usecase/mark_done.dart';
import 'package:oikerjain/feature/tasks/history/history_controller.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

import '../../../test_helpers.dart';

void main() {
  group('HistoryController', () {
    final clock = FixedClock(DateTime(2026, 2, 15, 9, 0));

    HistoryController createController(List<Task> seedTasks) {
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: seedTasks),
        clock: clock,
      );

      return HistoryController(
        getHistoryTasks: GetHistoryTasksUseCase(repository),
        markDone: MarkDoneUseCase(repository, FakeReminderScheduler()),
        deleteTask: DeleteTaskUseCase(repository, FakeReminderScheduler()),
      );
    }

    test('loads completed tasks only', () async {
      final controller = createController(<Task>[
        Task(
          id: 'done-1',
          title: 'Done',
          createdAtEpochMillis: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
          dueAtEpochMillis: DateTime(2026, 2, 11, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.medium,
          category: TaskCategory.work,
          isDone: true,
          completedAtEpochMillis:
              DateTime(2026, 2, 12, 10).millisecondsSinceEpoch,
          updatedAtEpochMillis:
              DateTime(2026, 2, 12, 10).millisecondsSinceEpoch,
        ),
        Task(
          id: 'active-1',
          title: 'Active',
          createdAtEpochMillis: DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
          dueAtEpochMillis: DateTime(2026, 2, 16, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.medium,
          category: TaskCategory.work,
          isDone: false,
          completedAtEpochMillis: null,
          updatedAtEpochMillis:
              DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
        ),
      ]);
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.state.tasks.map((task) => task.id), <String>['done-1']);
    });

    test('setDateRange applies createdAt filter and clearDateRange resets it', () async {
      final controller = createController(<Task>[
        Task(
          id: 'history-a',
          title: 'History A',
          createdAtEpochMillis: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
          dueAtEpochMillis: DateTime(2026, 2, 11, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.medium,
          category: TaskCategory.work,
          isDone: true,
          completedAtEpochMillis:
              DateTime(2026, 2, 12, 10).millisecondsSinceEpoch,
          updatedAtEpochMillis:
              DateTime(2026, 2, 12, 10).millisecondsSinceEpoch,
        ),
        Task(
          id: 'history-b',
          title: 'History B',
          createdAtEpochMillis: DateTime(2026, 2, 12, 9).millisecondsSinceEpoch,
          dueAtEpochMillis: DateTime(2026, 2, 13, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.medium,
          category: TaskCategory.work,
          isDone: true,
          completedAtEpochMillis:
              DateTime(2026, 2, 14, 10).millisecondsSinceEpoch,
          updatedAtEpochMillis:
              DateTime(2026, 2, 14, 10).millisecondsSinceEpoch,
        ),
      ]);
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.setDateRange(
        start: DateTime(2026, 2, 10),
        end: DateTime(2026, 2, 10),
      );

      expect(controller.state.tasks.map((task) => task.id), <String>['history-a']);

      await controller.clearDateRange();

      expect(
        controller.state.tasks.map((task) => task.id),
        <String>['history-b', 'history-a'],
      );
    });

    test('undoDone removes task from history list', () async {
      final controller = createController(<Task>[
        Task(
          id: 'history-undo',
          title: 'History Undo',
          createdAtEpochMillis: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
          dueAtEpochMillis: DateTime(2026, 2, 11, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.medium,
          category: TaskCategory.work,
          isDone: true,
          completedAtEpochMillis:
              DateTime(2026, 2, 12, 10).millisecondsSinceEpoch,
          updatedAtEpochMillis:
              DateTime(2026, 2, 12, 10).millisecondsSinceEpoch,
        ),
      ]);
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.undoDone('history-undo');

      expect(controller.state.tasks, isEmpty);
    });

    test('deleteTask removes task from history list', () async {
      final controller = createController(<Task>[
        Task(
          id: 'history-delete',
          title: 'History Delete',
          createdAtEpochMillis: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
          dueAtEpochMillis: DateTime(2026, 2, 11, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.medium,
          category: TaskCategory.work,
          isDone: true,
          completedAtEpochMillis:
              DateTime(2026, 2, 12, 10).millisecondsSinceEpoch,
          updatedAtEpochMillis:
              DateTime(2026, 2, 12, 10).millisecondsSinceEpoch,
        ),
      ]);
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.deleteTask('history-delete');

      expect(controller.state.tasks, isEmpty);
    });
  });
}
