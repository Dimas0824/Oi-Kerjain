import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/data/local/in_memory_task_store.dart';
import 'package:oikerjain/data/task_repository_impl.dart';
import 'package:oikerjain/domain/usecase/delete_task.dart';
import 'package:oikerjain/domain/usecase/get_tasks.dart';
import 'package:oikerjain/domain/usecase/mark_done.dart';
import 'package:oikerjain/feature/tasks/home/home_controller.dart';
import 'package:oikerjain/feature/tasks/home/home_state.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

import '../../../test_helpers.dart';

void main() {
  group('HomeController', () {
    final clock = FixedClock(DateTime(2026, 2, 15, 9, 0));

    HomeController createController() {
      final tasks = <Task>[
        Task(
          id: 'work-high',
          title: 'System Architecture',
          createdAtEpochMillis: DateTime(2026, 2, 15, 8).millisecondsSinceEpoch,
          dueAtEpochMillis: DateTime(2026, 2, 15, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.high,
          category: TaskCategory.work,
          isDone: false,
          completedAtEpochMillis: null,
          updatedAtEpochMillis: 20,
        ),
        Task(
          id: 'personal-mid',
          title: 'Car Service',
          createdAtEpochMillis: DateTime(2026, 2, 15, 7).millisecondsSinceEpoch,
          dueAtEpochMillis: DateTime(2026, 2, 15, 11).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.medium,
          category: TaskCategory.personal,
          isDone: false,
          completedAtEpochMillis: null,
          updatedAtEpochMillis: 10,
        ),
        Task(
          id: 'work-low',
          title: 'Client Workshop',
          createdAtEpochMillis: DateTime(2026, 2, 14, 12).millisecondsSinceEpoch,
          dueAtEpochMillis: DateTime(2026, 2, 16, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.low,
          category: TaskCategory.work,
          isDone: false,
          completedAtEpochMillis: null,
          updatedAtEpochMillis: 5,
        ),
        Task(
          id: 'done-hidden',
          title: 'Done Hidden',
          createdAtEpochMillis: DateTime(2026, 2, 13, 9).millisecondsSinceEpoch,
          dueAtEpochMillis: DateTime(2026, 2, 14, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.medium,
          category: TaskCategory.work,
          isDone: true,
          completedAtEpochMillis:
              DateTime(2026, 2, 14, 18).millisecondsSinceEpoch,
          updatedAtEpochMillis: DateTime(2026, 2, 14, 18).millisecondsSinceEpoch,
        ),
      ];

      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: tasks),
        clock: clock,
      );

      return HomeController(
        getTasks: GetTasksUseCase(repository),
        markDone: MarkDoneUseCase(repository, FakeReminderScheduler()),
        deleteTask: DeleteTaskUseCase(repository, FakeReminderScheduler()),
        clock: clock,
      );
    }

    test('filters by category and search query', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(
        controller.state.visibleTasks().map((task) => task.id).toList(),
        <String>['work-high', 'personal-mid', 'work-low'],
      );

      controller.setCategoryFilter(TaskCategoryFilter.personal);
      expect(
        controller.state.visibleTasks().map((task) => task.id).toList(),
        <String>['personal-mid'],
      );

      controller.setCategoryFilter(TaskCategoryFilter.all);
      controller.setSearchQuery('workshop');
      expect(
        controller.state.visibleTasks().map((task) => task.id).toList(),
        <String>['work-low'],
      );
    });

    test('toggleStatus marks task done and keeps it in home state for today', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.toggleStatus('work-high');

      expect(
        controller.state.tasks.map((task) => task.id),
        contains('work-high'),
      );
      expect(
        controller.state.tasks
            .firstWhere((task) => task.id == 'work-high')
            .isDone,
        isTrue,
      );
      expect(
        controller.state.visibleTasks().map((task) => task.id),
        isNot(contains('work-high')),
      );
      expect(
        controller.state.visibleCompletedTodayTasks().map((task) => task.id),
        contains('work-high'),
      );
    });

    test('deleteTask removes item', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.deleteTask('work-low');

      expect(
        controller.state.tasks.map((task) => task.id),
        isNot(contains('work-low')),
      );
    });

    test('criticalTask picks highest priority nearest due', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.refresh();
      final critical = controller.state.criticalTask();

      expect(critical?.id, 'work-high');
    });

    test('visibleTasks keeps only pending tasks sorted by priority and dueAt', () async {
      final now = clock.now();
      final tasks = <Task>[
        Task(
          id: 'pending-low',
          title: 'Pending Low',
          createdAtEpochMillis: now.millisecondsSinceEpoch,
          dueAtEpochMillis:
              now.add(const Duration(hours: 8)).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.low,
          category: TaskCategory.work,
          isDone: false,
          completedAtEpochMillis: null,
          updatedAtEpochMillis: now.millisecondsSinceEpoch - 1000,
        ),
        Task(
          id: 'pending-high-near',
          title: 'Pending High Near',
          createdAtEpochMillis: now.millisecondsSinceEpoch,
          dueAtEpochMillis:
              now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.high,
          category: TaskCategory.work,
          isDone: false,
          completedAtEpochMillis: null,
          updatedAtEpochMillis: now.millisecondsSinceEpoch - 2000,
        ),
        Task(
          id: 'done-recent',
          title: 'Done Recent',
          createdAtEpochMillis:
              now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          dueAtEpochMillis:
              now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.high,
          category: TaskCategory.work,
          isDone: true,
          completedAtEpochMillis:
              now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
          updatedAtEpochMillis:
              now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        ),
      ];

      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: tasks),
        clock: clock,
      );

      final controller = HomeController(
        getTasks: GetTasksUseCase(repository),
        markDone: MarkDoneUseCase(repository, FakeReminderScheduler()),
        deleteTask: DeleteTaskUseCase(repository, FakeReminderScheduler()),
        clock: clock,
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(
        controller.state.visibleTasks().map((task) => task.id).toList(),
        <String>['pending-high-near', 'pending-low'],
      );
      expect(
        controller.state.visibleCompletedTodayTasks().map((task) => task.id).toList(),
        <String>['done-recent'],
      );
    });

    test('visibleCompletedTodayTasks follows category and search filters', () async {
      final now = clock.now();
      final tasks = <Task>[
        Task(
          id: 'done-work',
          title: 'Deploy Service',
          createdAtEpochMillis: now.millisecondsSinceEpoch,
          dueAtEpochMillis: now.millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.medium,
          category: TaskCategory.work,
          isDone: true,
          completedAtEpochMillis:
              now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
          updatedAtEpochMillis:
              now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
        ),
        Task(
          id: 'done-personal',
          title: 'Car Wash',
          createdAtEpochMillis: now.millisecondsSinceEpoch,
          dueAtEpochMillis: now.millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.low,
          category: TaskCategory.personal,
          isDone: true,
          completedAtEpochMillis:
              now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
          updatedAtEpochMillis:
              now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        ),
      ];

      final repository = TaskRepositoryImpl(
        InMemoryTaskStore(clock: clock, seedTasks: tasks),
        clock: clock,
      );

      final controller = HomeController(
        getTasks: GetTasksUseCase(repository),
        markDone: MarkDoneUseCase(repository, FakeReminderScheduler()),
        deleteTask: DeleteTaskUseCase(repository, FakeReminderScheduler()),
        clock: clock,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(
        controller.state.visibleCompletedTodayTasks().map((task) => task.id).toList(),
        <String>['done-personal', 'done-work'],
      );

      controller.setCategoryFilter(TaskCategoryFilter.work);
      expect(
        controller.state.visibleCompletedTodayTasks().map((task) => task.id).toList(),
        <String>['done-work'],
      );

      controller.setCategoryFilter(TaskCategoryFilter.all);
      controller.setSearchQuery('car');
      expect(
        controller.state.visibleCompletedTodayTasks().map((task) => task.id).toList(),
        <String>['done-personal'],
      );
    });
  });
}
