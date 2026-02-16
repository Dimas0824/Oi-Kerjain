import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/core/utils/id.dart';
import 'package:oikerjain/data/local/in_memory_task_store.dart';
import 'package:oikerjain/data/task_repository_impl.dart';
import 'package:oikerjain/domain/usecase/upsert_task.dart';
import 'package:oikerjain/feature/tasks/edit/edit_controller.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

import '../../../test_helpers.dart';

void main() {
  group('EditController', () {
    final clock = FixedClock(DateTime(2026, 2, 15, 9, 45));

    test('submit fails when title is empty', () async {
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: const <Task>[]),
        clock: clock,
      );
      final controller = EditController(
        upsertTask: UpsertTaskUseCase(repository, FakeReminderScheduler()),
        idGenerator: IdGenerator(),
        clock: clock,
      );
      addTearDown(controller.dispose);

      final result = await controller.submit();

      expect(result, isFalse);
      expect(controller.state.errorMessage, isNotNull);
    });

    test('empty date and time use defaults', () async {
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: const <Task>[]),
        clock: clock,
      );
      final controller = EditController(
        upsertTask: UpsertTaskUseCase(repository, FakeReminderScheduler()),
        idGenerator: IdGenerator(),
        clock: clock,
      );
      addTearDown(controller.dispose);

      controller.setTitle('Task Baru');
      final result = await controller.submit();

      expect(result, isTrue);
      final tasks = await repository.getTasks();
      final dueAt = DateTime.fromMillisecondsSinceEpoch(
        tasks.single.dueAtEpochMillis,
      );
      expect(dueAt.year, 2026);
      expect(dueAt.month, 2);
      expect(dueAt.day, 15);
      expect(dueAt.hour, 12);
      expect(dueAt.minute, 0);
    });

    test('dd-mm-yyyy deadline and hour input are accepted', () async {
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: const <Task>[]),
        clock: clock,
      );
      final controller = EditController(
        upsertTask: UpsertTaskUseCase(repository, FakeReminderScheduler()),
        idGenerator: IdGenerator(),
        clock: clock,
      );
      addTearDown(controller.dispose);

      controller.setTitle('Task Baru');
      controller.setDueDateText('16-02-2026');
      controller.setDueTimeText('11');

      final result = await controller.submit();

      expect(result, isTrue);
      final tasks = await repository.getTasks();
      final dueAt = DateTime.fromMillisecondsSinceEpoch(
        tasks.single.dueAtEpochMillis,
      );
      expect(dueAt.year, 2026);
      expect(dueAt.month, 2);
      expect(dueAt.day, 16);
      expect(dueAt.hour, 11);
      expect(dueAt.minute, 0);
    });

    test('invalid time fails validation', () async {
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: const <Task>[]),
        clock: clock,
      );
      final controller = EditController(
        upsertTask: UpsertTaskUseCase(repository, FakeReminderScheduler()),
        idGenerator: IdGenerator(),
        clock: clock,
      );
      addTearDown(controller.dispose);

      controller.setTitle('Task Baru');
      controller.setDueTimeText('25:99');
      final result = await controller.submit();

      expect(result, isFalse);
      expect(controller.state.errorMessage, contains('Format waktu'));
    });

    test('submit stores repeat, category, and priority', () async {
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: const <Task>[]),
        clock: clock,
      );
      final controller = EditController(
        upsertTask: UpsertTaskUseCase(repository, FakeReminderScheduler()),
        idGenerator: IdGenerator(),
        clock: clock,
      );
      addTearDown(controller.dispose);

      controller.setTitle('Task Repeat');
      controller.setRepeatRule(RepeatRule.weekly);
      controller.setCategory(TaskCategory.personal);
      controller.setPriority(TaskPriority.high);

      final result = await controller.submit();
      final tasks = await repository.getTasks();

      expect(result, isTrue);
      expect(tasks.single.repeatRule, RepeatRule.weekly);
      expect(tasks.single.category, TaskCategory.personal);
      expect(tasks.single.priority, TaskPriority.high);
    });

    test('edit mode updates existing task id', () async {
      final existingTask = Task(
        id: 'task-123',
        title: 'Old title',
        description: '',
        dueAtEpochMillis: DateTime(2026, 2, 15, 9).millisecondsSinceEpoch,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.medium,
        category: TaskCategory.work,
        isDone: false,
        updatedAtEpochMillis: 1,
      );
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: <Task>[existingTask]),
        clock: clock,
      );
      final controller = EditController(
        upsertTask: UpsertTaskUseCase(repository, FakeReminderScheduler()),
        idGenerator: IdGenerator(),
        clock: clock,
        initialTask: existingTask,
      );
      addTearDown(controller.dispose);

      controller.setTitle('New title');
      final result = await controller.submit();

      expect(result, isTrue);
      final tasks = await repository.getTasks();
      expect(tasks.single.id, 'task-123');
      expect(tasks.single.title, 'New title');
    });

    test('submit succeeds when reminder scheduling fails', () async {
      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: const <Task>[]),
        clock: clock,
      );
      final controller = EditController(
        upsertTask: UpsertTaskUseCase(repository, _ThrowingReminderScheduler()),
        idGenerator: IdGenerator(),
        clock: clock,
      );
      addTearDown(controller.dispose);

      controller.setTitle('Task Baru');
      controller.setDueDateText('16-02-2026');
      controller.setDueTimeText('11:30');

      final result = await controller.submit();

      expect(result, isTrue);
      expect(controller.state.errorMessage, isNull);
      final tasks = await repository.getTasks();
      expect(tasks, hasLength(1));
      expect(tasks.single.title, 'Task Baru');
    });
  });
}

class _ThrowingReminderScheduler extends FakeReminderScheduler {
  @override
  Future<void> schedule(Task task) async {
    throw Exception('scheduler unavailable');
  }
}
