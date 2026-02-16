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

    test('getTasks returns active tasks sorted by priority/due/updated', () async {
      final store = InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[
          Task(
            id: 'm2',
            title: 'medium new',
            createdAtEpochMillis:
                DateTime(2026, 2, 14, 8).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 16, 8).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: false,
            completedAtEpochMillis: null,
            updatedAtEpochMillis: 200,
          ),
          Task(
            id: 'h-late',
            title: 'high late',
            createdAtEpochMillis:
                DateTime(2026, 2, 14, 8).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 15, 18).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.high,
            category: TaskCategory.work,
            isDone: false,
            completedAtEpochMillis: null,
            updatedAtEpochMillis: 100,
          ),
          Task(
            id: 'l1',
            title: 'low',
            createdAtEpochMillis:
                DateTime(2026, 2, 14, 8).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 15, 7).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.low,
            category: TaskCategory.personal,
            isDone: false,
            completedAtEpochMillis: null,
            updatedAtEpochMillis: 900,
          ),
          Task(
            id: 'h-early',
            title: 'high early',
            createdAtEpochMillis:
                DateTime(2026, 2, 14, 8).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 15, 9).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.high,
            category: TaskCategory.personal,
            isDone: false,
            completedAtEpochMillis: null,
            updatedAtEpochMillis: 300,
          ),
          Task(
            id: 'done-hidden',
            title: 'done hidden',
            createdAtEpochMillis:
                DateTime(2026, 2, 10, 8).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.high,
            category: TaskCategory.personal,
            isDone: true,
            completedAtEpochMillis:
                DateTime(2026, 2, 14, 10).millisecondsSinceEpoch,
            updatedAtEpochMillis:
                DateTime(2026, 2, 14, 10).millisecondsSinceEpoch,
          ),
          Task(
            id: 'm1',
            title: 'medium old',
            createdAtEpochMillis:
                DateTime(2026, 2, 14, 8).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 16, 8).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: false,
            completedAtEpochMillis: null,
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

    test('markDone updates completedAt and supports undo', () async {
      final sourceTask = Task(
        id: 'task-x',
        title: 'Task X',
        createdAtEpochMillis: DateTime(2026, 2, 15, 8).millisecondsSinceEpoch,
        dueAtEpochMillis: DateTime(2026, 2, 15, 10).millisecondsSinceEpoch,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.medium,
        category: TaskCategory.work,
        isDone: false,
        completedAtEpochMillis: null,
        updatedAtEpochMillis: 1,
      );
      final store = InMemoryTaskStore(clock: clock, seedTasks: <Task>[sourceTask]);
      final repository = TaskRepositoryImpl(store, clock: clock);

      await repository.markDone('task-x', isDone: true);

      final activeAfterDone = await repository.getTasks();
      final historyAfterDone = await repository.getHistoryTasks();

      expect(activeAfterDone.single.id, 'task-x');
      expect(activeAfterDone.single.isDone, isTrue);
      expect(historyAfterDone, isEmpty);
      expect(
        activeAfterDone.single.completedAtEpochMillis,
        clock.now().millisecondsSinceEpoch,
      );

      await repository.markDone('task-x', isDone: false);

      final activeAfterUndo = await repository.getTasks();
      expect(activeAfterUndo.single.isDone, isFalse);
      expect(activeAfterUndo.single.completedAtEpochMillis, isNull);
    });

    test(
      'classifies done task by local-day boundary for active vs history',
      () async {
        final now = clock.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        final beforeTodayStart = todayStart.subtract(const Duration(milliseconds: 1));

        final store = InMemoryTaskStore(
          clock: clock,
          seedTasks: <Task>[
            Task(
              id: 'done-at-start',
              title: 'Done At Start',
              createdAtEpochMillis:
                  now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
              dueAtEpochMillis:
                  now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
              repeatRule: RepeatRule.none,
              priority: TaskPriority.high,
              category: TaskCategory.work,
              isDone: true,
              completedAtEpochMillis: todayStart.millisecondsSinceEpoch,
              updatedAtEpochMillis: todayStart.millisecondsSinceEpoch,
            ),
            Task(
              id: 'done-at-end',
              title: 'Done At End',
              createdAtEpochMillis:
                  now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
              dueAtEpochMillis:
                  now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
              repeatRule: RepeatRule.none,
              priority: TaskPriority.high,
              category: TaskCategory.work,
              isDone: true,
              completedAtEpochMillis: todayEnd.millisecondsSinceEpoch,
              updatedAtEpochMillis: todayEnd.millisecondsSinceEpoch,
            ),
            Task(
              id: 'done-before-start',
              title: 'Done Before Start',
              createdAtEpochMillis:
                  now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
              dueAtEpochMillis:
                  now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
              repeatRule: RepeatRule.none,
              priority: TaskPriority.medium,
              category: TaskCategory.work,
              isDone: true,
              completedAtEpochMillis: beforeTodayStart.millisecondsSinceEpoch,
              updatedAtEpochMillis: beforeTodayStart.millisecondsSinceEpoch,
            ),
          ],
        );
        final repository = TaskRepositoryImpl(store, clock: clock);

        final active = await repository.getTasks();
        final history = await repository.getHistoryTasks();

        expect(
          active.map((task) => task.id),
          containsAll(<String>['done-at-start', 'done-at-end']),
        );
        expect(
          active.map((task) => task.id),
          isNot(contains('done-before-start')),
        );
        expect(history.map((task) => task.id), <String>['done-before-start']);
      },
    );

    test('snoozeTask preserves dueAt and sets snoozedUntil', () async {
      final baseDueAt = DateTime(2026, 2, 15, 10).millisecondsSinceEpoch;
      final store = InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[
          Task(
            id: 'task-x',
            title: 'Task X',
            createdAtEpochMillis: DateTime(2026, 2, 15, 8).millisecondsSinceEpoch,
            dueAtEpochMillis: baseDueAt,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: false,
            completedAtEpochMillis: null,
            updatedAtEpochMillis: 1,
          )
        ],
      );
      final repository = TaskRepositoryImpl(store, clock: clock);

      await repository.snoozeTask('task-x');
      final tasks = await repository.getTasks();

      expect(tasks.single.dueAtEpochMillis, baseDueAt);
      expect(
        tasks.single.snoozedUntilEpochMillis,
        clock.now().millisecondsSinceEpoch +
            const Duration(minutes: 10).inMilliseconds,
      );
    });

    test('snoozeTask clamps snoozedUntil to dueAt', () async {
      final dueAt = DateTime(2026, 2, 15, 9, 30).millisecondsSinceEpoch;
      final store = InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[
          Task(
            id: 'task-clamp',
            title: 'Task Clamp',
            createdAtEpochMillis: DateTime(2026, 2, 15, 8).millisecondsSinceEpoch,
            dueAtEpochMillis: dueAt,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: false,
            completedAtEpochMillis: null,
            updatedAtEpochMillis: 1,
          )
        ],
      );
      final repository = TaskRepositoryImpl(store, clock: clock);

      await repository.snoozeTask('task-clamp', by: const Duration(hours: 2));
      final task = (await repository.getTasks()).single;

      expect(task.snoozedUntilEpochMillis, dueAt);
      expect(task.dueAtEpochMillis, dueAt);
    });

    test('markDone clears snoozedUntil', () async {
      final dueAt = DateTime(2026, 2, 15, 10).millisecondsSinceEpoch;
      final snoozedUntil = DateTime(2026, 2, 15, 9, 30).millisecondsSinceEpoch;
      final store = InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[
          Task(
            id: 'task-done',
            title: 'Task Done',
            createdAtEpochMillis: DateTime(2026, 2, 15, 8).millisecondsSinceEpoch,
            dueAtEpochMillis: dueAt,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: false,
            completedAtEpochMillis: null,
            snoozedUntilEpochMillis: snoozedUntil,
            updatedAtEpochMillis: 1,
          )
        ],
      );
      final repository = TaskRepositoryImpl(store, clock: clock);

      await repository.markDone('task-done', isDone: true);
      final task = (await repository.getTasks()).single;

      expect(task.snoozedUntilEpochMillis, isNull);
    });

    test('undo markDone keeps snoozedUntil cleared', () async {
      final dueAt = DateTime(2026, 2, 15, 10).millisecondsSinceEpoch;
      final store = InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[
          Task(
            id: 'task-undo',
            title: 'Task Undo',
            createdAtEpochMillis: DateTime(2026, 2, 15, 8).millisecondsSinceEpoch,
            dueAtEpochMillis: dueAt,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: false,
            completedAtEpochMillis: null,
            snoozedUntilEpochMillis: DateTime(
              2026,
              2,
              15,
              9,
              15,
            ).millisecondsSinceEpoch,
            updatedAtEpochMillis: 1,
          )
        ],
      );
      final repository = TaskRepositoryImpl(store, clock: clock);

      await repository.markDone('task-undo', isDone: true);
      await repository.markDone('task-undo', isDone: false);
      final task = (await repository.getTasks()).single;

      expect(task.snoozedUntilEpochMillis, isNull);
      expect(task.dueAtEpochMillis, dueAt);
    });

    test('repeat roll-forward can clear snooze metadata via copyWith', () {
      final task = Task(
        id: 'task-repeat',
        title: 'Task Repeat',
        createdAtEpochMillis: DateTime(2026, 2, 12, 8).millisecondsSinceEpoch,
        dueAtEpochMillis: DateTime(2026, 2, 13, 8).millisecondsSinceEpoch,
        repeatRule: RepeatRule.daily,
        priority: TaskPriority.medium,
        category: TaskCategory.work,
        isDone: false,
        completedAtEpochMillis: null,
        snoozedUntilEpochMillis: DateTime(2026, 2, 13, 9).millisecondsSinceEpoch,
        updatedAtEpochMillis: 1,
      );

      final rolled = task.copyWith(
        dueAtEpochMillis: DateTime(2026, 2, 14, 8).millisecondsSinceEpoch,
        clearSnoozedUntilEpochMillis: true,
      );

      expect(rolled.snoozedUntilEpochMillis, isNull);
    });

    test('cleanup removes completed tasks older than 14 days', () async {
      final now = clock.now();
      final store = InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[
          Task(
            id: 'done-recent',
            title: 'Done Recent',
            createdAtEpochMillis:
                now.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
            dueAtEpochMillis:
                now.subtract(const Duration(days: 4)).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: true,
            completedAtEpochMillis:
                now.subtract(const Duration(days: 13)).millisecondsSinceEpoch,
            updatedAtEpochMillis:
                now.subtract(const Duration(days: 13)).millisecondsSinceEpoch,
          ),
          Task(
            id: 'done-expired',
            title: 'Done Expired',
            createdAtEpochMillis:
                now.subtract(const Duration(days: 20)).millisecondsSinceEpoch,
            dueAtEpochMillis:
                now.subtract(const Duration(days: 20)).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.medium,
            category: TaskCategory.work,
            isDone: true,
            completedAtEpochMillis:
                now.subtract(const Duration(days: 15)).millisecondsSinceEpoch,
            updatedAtEpochMillis:
                now.subtract(const Duration(days: 15)).millisecondsSinceEpoch,
          ),
        ],
      );

      final repository = TaskRepositoryImpl(store, clock: clock);

      final history = await repository.getHistoryTasks();
      final persisted = await store.readAll();

      expect(history.map((task) => task.id), <String>['done-recent']);
      expect(persisted.map((task) => task.id), <String>['done-recent']);
    });

    test('getHistoryTasks filters by createdAt range inclusively', () async {
      final store = InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[
          Task(
            id: 'history-a',
            title: 'History A',
            createdAtEpochMillis:
                DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 11, 9).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.low,
            category: TaskCategory.personal,
            isDone: true,
            completedAtEpochMillis:
                DateTime(2026, 2, 12, 9).millisecondsSinceEpoch,
            updatedAtEpochMillis:
                DateTime(2026, 2, 12, 9).millisecondsSinceEpoch,
          ),
          Task(
            id: 'history-b',
            title: 'History B',
            createdAtEpochMillis:
                DateTime(2026, 2, 12, 9).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 13, 9).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.low,
            category: TaskCategory.personal,
            isDone: true,
            completedAtEpochMillis:
                DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
            updatedAtEpochMillis:
                DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
          ),
        ],
      );

      final repository = TaskRepositoryImpl(store, clock: clock);

      final singleDay = await repository.getHistoryTasks(
        start: DateTime(2026, 2, 10),
        end: DateTime(2026, 2, 10),
      );
      final twoDays = await repository.getHistoryTasks(
        start: DateTime(2026, 2, 10),
        end: DateTime(2026, 2, 12),
      );

      expect(singleDay.map((task) => task.id), <String>['history-a']);
      expect(twoDays.map((task) => task.id), <String>['history-b', 'history-a']);
    });

    test('getHistoryTasks includes monday start and sunday end boundaries', () async {
      final store = InMemoryTaskStore(
        clock: clock,
        seedTasks: <Task>[
          Task(
            id: 'monday-start',
            title: 'Monday Start',
            createdAtEpochMillis:
                DateTime(2026, 2, 9, 0, 0, 0, 0).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 9, 9).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.low,
            category: TaskCategory.personal,
            isDone: true,
            completedAtEpochMillis:
                DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
            updatedAtEpochMillis:
                DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
          ),
          Task(
            id: 'sunday-end',
            title: 'Sunday End',
            createdAtEpochMillis:
                DateTime(2026, 2, 15, 23, 59, 59, 999).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 15, 9).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.low,
            category: TaskCategory.personal,
            isDone: true,
            completedAtEpochMillis:
                DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
            updatedAtEpochMillis:
                DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
          ),
          Task(
            id: 'before-range',
            title: 'Before Range',
            createdAtEpochMillis:
                DateTime(2026, 2, 8, 23, 59, 59, 999).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 8, 9).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.low,
            category: TaskCategory.personal,
            isDone: true,
            completedAtEpochMillis:
                DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
            updatedAtEpochMillis:
                DateTime(2026, 2, 10, 9).millisecondsSinceEpoch,
          ),
          Task(
            id: 'after-range',
            title: 'After Range',
            createdAtEpochMillis:
                DateTime(2026, 2, 16, 0, 0, 0, 0).millisecondsSinceEpoch,
            dueAtEpochMillis: DateTime(2026, 2, 16, 9).millisecondsSinceEpoch,
            repeatRule: RepeatRule.none,
            priority: TaskPriority.low,
            category: TaskCategory.personal,
            isDone: true,
            completedAtEpochMillis:
                DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
            updatedAtEpochMillis:
                DateTime(2026, 2, 14, 9).millisecondsSinceEpoch,
          ),
        ],
      );

      final repository = TaskRepositoryImpl(store, clock: clock);

      final weekly = await repository.getHistoryTasks(
        start: DateTime(2026, 2, 9),
        end: DateTime(2026, 2, 15),
      );

      expect(weekly.map((task) => task.id), <String>['sunday-end', 'monday-start']);
    });
  });
}
