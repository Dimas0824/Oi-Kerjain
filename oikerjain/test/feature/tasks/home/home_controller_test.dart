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
          dueAtEpochMillis: DateTime(2026, 2, 15, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.high,
          category: TaskCategory.work,
          isDone: false,
          updatedAtEpochMillis: 20,
        ),
        Task(
          id: 'personal-mid',
          title: 'Car Service',
          dueAtEpochMillis: DateTime(2026, 2, 15, 11).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.medium,
          category: TaskCategory.personal,
          isDone: false,
          updatedAtEpochMillis: 10,
        ),
        Task(
          id: 'work-low',
          title: 'Client Workshop',
          dueAtEpochMillis: DateTime(2026, 2, 16, 10).millisecondsSinceEpoch,
          repeatRule: RepeatRule.none,
          priority: TaskPriority.low,
          category: TaskCategory.work,
          isDone: false,
          updatedAtEpochMillis: 5,
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

    test('toggleStatus marks task done', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      await controller.refresh();
      await controller.toggleStatus('work-high');

      final updated = controller.state.tasks
          .where((task) => task.id == 'work-high')
          .single;
      expect(updated.isDone, isTrue);
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
  });
}
