import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/core/constants/notification_const.dart';
import 'package:oikerjain/data/local/in_memory_task_store.dart';
import 'package:oikerjain/data/task_repository_impl.dart';
import 'package:oikerjain/domain/usecase/compute_next_occurrence.dart';
import 'package:oikerjain/domain/usecase/handle_notification_action.dart';
import 'package:oikerjain/domain/usecase/mark_done.dart';
import 'package:oikerjain/domain/usecase/snooze_task.dart';
import 'package:oikerjain/domain/usecase/upsert_task.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

import '../test_helpers.dart';

void main() {
  group('HandleNotificationActionUseCase', () {
    final clock = FixedClock(DateTime(2026, 2, 15, 9, 0));

    HandleNotificationActionUseCase buildUseCase(
      TaskRepositoryImpl repository,
    ) {
      final scheduler = FakeReminderScheduler();
      return HandleNotificationActionUseCase(
        repository,
        MarkDoneUseCase(repository, scheduler),
        SnoozeTaskUseCase(repository, scheduler),
        UpsertTaskUseCase(repository, scheduler),
        const ComputeNextOccurrenceUseCase(),
        clock: clock,
      );
    }

    Task buildTask({
      required String id,
      required DateTime dueAt,
      RepeatRule repeatRule = RepeatRule.none,
      int? snoozedUntilEpochMillis,
    }) {
      return Task(
        id: id,
        title: 'Task',
        createdAtEpochMillis: DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
        dueAtEpochMillis: dueAt.millisecondsSinceEpoch,
        repeatRule: repeatRule,
        priority: TaskPriority.medium,
        category: TaskCategory.work,
        isDone: false,
        completedAtEpochMillis: null,
        snoozedUntilEpochMillis: snoozedUntilEpochMillis,
        updatedAtEpochMillis: DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
      );
    }

    test('SNOOZE_1H sets snoozedUntil without changing dueAt', () async {
      final sourceTask = buildTask(id: 'task-1', dueAt: DateTime(2026, 2, 15, 12));
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: <Task>[sourceTask]),
        clock: clock,
      );
      final useCase = buildUseCase(repository);

      await useCase(taskId: sourceTask.id, actionId: NotificationConst.actionSnooze1h);
      final task = (await repository.getTasks()).single;

      expect(task.dueAtEpochMillis, sourceTask.dueAtEpochMillis);
      expect(
        task.snoozedUntilEpochMillis,
        clock.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      );
    });

    test('SNOOZE_4H clamps snooze to dueAt', () async {
      final sourceTask = buildTask(id: 'task-2', dueAt: DateTime(2026, 2, 15, 11));
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: <Task>[sourceTask]),
        clock: clock,
      );
      final useCase = buildUseCase(repository);

      await useCase(taskId: sourceTask.id, actionId: NotificationConst.actionSnooze4h);
      final task = (await repository.getTasks()).single;

      expect(task.snoozedUntilEpochMillis, sourceTask.dueAtEpochMillis);
    });

    test('SNOOZE_CUSTOM adds 1 hour', () async {
      final sourceTask = buildTask(id: 'task-3', dueAt: DateTime(2026, 2, 15, 15));
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: <Task>[sourceTask]),
        clock: clock,
      );
      final useCase = buildUseCase(repository);

      await useCase(taskId: sourceTask.id, actionId: NotificationConst.actionSnoozeCustom);
      final task = (await repository.getTasks()).single;

      expect(
        task.snoozedUntilEpochMillis,
        clock.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      );
    });

    test('legacy SNOOZE_10M remains supported', () async {
      final sourceTask = buildTask(id: 'task-4', dueAt: DateTime(2026, 2, 15, 12));
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: <Task>[sourceTask]),
        clock: clock,
      );
      final useCase = buildUseCase(repository);

      await useCase(
        taskId: sourceTask.id,
        actionId: NotificationConst.actionSnooze10mLegacy,
      );
      final task = (await repository.getTasks()).single;

      expect(
        task.snoozedUntilEpochMillis,
        clock.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
      );
    });

    test('DONE marks task done', () async {
      final sourceTask = buildTask(id: 'task-5', dueAt: DateTime(2026, 2, 15, 12));
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: <Task>[sourceTask]),
        clock: clock,
      );
      final useCase = buildUseCase(repository);

      await useCase(taskId: sourceTask.id, actionId: NotificationConst.actionDone);
      final task = (await repository.getTasks()).single;

      expect(task.isDone, isTrue);
      expect(task.completedAtEpochMillis, clock.now().millisecondsSinceEpoch);
      expect(task.snoozedUntilEpochMillis, isNull);
    });

    test('unknown action rolls overdue repeating task and clears snooze', () async {
      final sourceTask = buildTask(
        id: 'task-repeat',
        dueAt: DateTime(2026, 2, 14, 9),
        repeatRule: RepeatRule.daily,
        snoozedUntilEpochMillis: DateTime(2026, 2, 14, 10).millisecondsSinceEpoch,
      );
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: <Task>[sourceTask]),
        clock: clock,
      );
      final useCase = buildUseCase(repository);

      await useCase(taskId: sourceTask.id, actionId: 'UNKNOWN');
      final task = (await repository.getTasks()).single;

      expect(
        DateTime.fromMillisecondsSinceEpoch(task.dueAtEpochMillis),
        DateTime(2026, 2, 16, 9),
      );
      expect(task.snoozedUntilEpochMillis, isNull);
    });
  });
}
