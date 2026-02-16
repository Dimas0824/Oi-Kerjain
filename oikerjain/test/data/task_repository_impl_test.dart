import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/data/local/in_memory_task_store.dart';
import 'package:oikerjain/data/task_repository_impl.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

import '../test_helpers.dart';

void main() {
  group('TaskRepositoryImpl', () {
    final clock = FixedClock(DateTime(2026, 2, 15, 9));

    test('sorts by priority desc, dueAt asc, updatedAt desc', () async {
      final store = InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[
          Task(
            id: 'm2',
            title: 'medium new',
            dueAtEpochMillis: DateTime(2026, 2, 16, 8).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: false,
            updatedAtEpochMillis: 200,
          ),
          Task(
            id: 'h-late',
            title: 'high late',
            dueAtEpochMillis: DateTime(2026, 2, 15, 18).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.high,
            category: TaskCategory.work,
            isDone: false,
            updatedAtEpochMillis: 100,
          ),
          Task(
            id: 'l1',
            title: 'low',
            dueAtEpochMillis: DateTime(2026, 2, 15, 7).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.low,
            category: TaskCategory.personal,
            isDone: false,
            updatedAtEpochMillis: 900,
          ),
          Task(
            id: 'h-early',
            title: 'high early',
            dueAtEpochMillis: DateTime(2026, 2, 15, 9).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.high,
            category: TaskCategory.personal,
            isDone: false,
            updatedAtEpochMillis: 300,
          ),
          Task(
            id: 'm1',
            title: 'medium old',
            dueAtEpochMillis: DateTime(2026, 2, 16, 8).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: false,
            updatedAtEpochMillis: 100,
          ),
        ],
      );

      final repository = TaskRepositoryImpl(store, clock: clock);
      final tasks = await repository.getTasks();

      expect(
        tasks.map((task) => task.id).toList(),
        <String>['h-early', 'h-late', 'm2', 'm1', 'l1'],
      );
    });

    test('markDone updates status and timestamp', () async {
      final sourceTask = Task(
        id: 'task-x',
        title: 'Task X',
        dueAtEpochMillis: DateTime(2026, 2, 15, 10).millisecondsSinceEpoch,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.medium,
        category: TaskCategory.work,
        isDone: false,
        updatedAtEpochMillis: 1,
      );
      final store = InMemoryTaskStore(clock: clock, seedTasks: <Task>[sourceTask]);
      final repository = TaskRepositoryImpl(store, clock: clock);

      await repository.markDone('task-x', isDone: true);
      final tasks = await repository.getTasks();

      expect(tasks.single.isDone, isTrue);
      expect(tasks.single.updatedAtEpochMillis, clock.now().millisecondsSinceEpoch);
    });

    test('snoozeTask shifts dueAt by 10 minutes', () async {
      final baseDueAt = DateTime(2026, 2, 15, 10).millisecondsSinceEpoch;
      final store = InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[
          Task(
            id: 'task-x',
            title: 'Task X',
            dueAtEpochMillis: baseDueAt,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: false,
            updatedAtEpochMillis: 1,
          )
        ],
      );
      final repository = TaskRepositoryImpl(store, clock: clock);

      await repository.snoozeTask('task-x');
      final tasks = await repository.getTasks();

      expect(
        tasks.single.dueAtEpochMillis,
        baseDueAt + const Duration(minutes: 10).inMilliseconds,
      );
    });
  });
}
