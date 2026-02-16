import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oikerjain/app/di.dart';
import 'package:oikerjain/data/local/in_memory_task_store.dart';
import 'package:oikerjain/feature/tasks/home/home_page.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

import 'test_helpers.dart';

void main() {
  final fixedClock = FixedClock(DateTime(2026, 2, 15, 9, 30));

  Task buildTask({
    required String id,
    required String title,
    required DateTime dueAt,
    DateTime? createdAt,
    TaskPriority priority = TaskPriority.medium,
    TaskCategory category = TaskCategory.work,
    bool isDone = false,
    DateTime? completedAt,
  }) {
    final created = createdAt ?? dueAt.subtract(const Duration(days: 1));
    final updatedAt = completedAt ?? fixedClock.now();

    return Task(
      id: id,
      title: title,
      createdAtEpochMillis: created.millisecondsSinceEpoch,
      dueAtEpochMillis: dueAt.millisecondsSinceEpoch,
      repeatRule: RepeatRule.none,
      priority: priority,
      category: category,
      isDone: isDone,
      completedAtEpochMillis: completedAt?.millisecondsSinceEpoch,
      updatedAtEpochMillis: updatedAt.millisecondsSinceEpoch,
    );
  }

  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    List<Task> seedTasks = const <Task>[],
  }) async {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(fixedClock),
        taskStoreProvider.overrideWithValue(
          InMemoryTaskStore(clock: fixedClock, seedTasks: seedTasks),
        ),
        reminderSchedulerProvider.overrideWithValue(FakeReminderScheduler()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomePage()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return container;
  }

  testWidgets('home renders active layout with bottom navigation tabs', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('Tugas aktif'), findsOneWidget);
    expect(find.text('Belum ada tugas yang cocok.'), findsOneWidget);
    expect(find.byKey(const Key('search-input')), findsOneWidget);
    expect(find.byKey(const Key('nav-active-tab')), findsOneWidget);
    expect(find.byKey(const Key('nav-history-tab')), findsOneWidget);
    expect(find.byKey(const Key('nav-add-button')), findsOneWidget);
  });

  testWidgets('category filter can be tapped', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('filter-personal')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Belum ada tugas yang cocok.'), findsOneWidget);
  });

  testWidgets('search filters active task list', (tester) async {
    final seededTasks = <Task>[
      buildTask(
        id: 'task-search-1',
        title: 'System Architecture',
        dueAt: DateTime(2026, 2, 15, 11),
        priority: TaskPriority.high,
      ),
      buildTask(
        id: 'task-search-2',
        title: 'Car Service',
        dueAt: DateTime(2026, 2, 15, 12),
        category: TaskCategory.personal,
      ),
    ];

    await pumpHome(tester, seedTasks: seededTasks);

    await tester.enterText(find.byKey(const Key('search-input')), 'car');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('task-card-task-search-2')), findsOneWidget);
    expect(find.byKey(const Key('task-card-task-search-1')), findsNothing);
  });

  testWidgets('tap active task toggles done and keeps it on active tab for today', (
    tester,
  ) async {
    final seededTask = buildTask(
      id: 'task-1',
      title: 'Task Toggle',
      dueAt: DateTime(2026, 2, 15, 11, 20),
    );

    await pumpHome(tester, seedTasks: <Task>[seededTask]);

    expect(find.byKey(const Key('task-card-task-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('task-card-task-1')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('task-card-task-1')), findsOneWidget);
    expect(find.byKey(const Key('completed-today-section')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-history-tab')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('history-task-card-task-1')), findsNothing);
  });

  testWidgets('add flow from active tab bottom sheet creates task', (tester) async {
    await pumpHome(tester);

    await tester.ensureVisible(find.byKey(const Key('nav-add-button')));
    await tester.tap(
      find.byKey(const Key('nav-add-button')),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 700));

    await tester.enterText(
      find.byKey(const Key('task-title-input')),
      'Task From Widget Test',
    );

    await tester.ensureVisible(find.byKey(const Key('save-task-button')));
    await tester.tap(
      find.byKey(const Key('save-task-button')),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Task From Widget Test'), findsOneWidget);
  });

  testWidgets('add flow from history tab opens sheet without switching tabs', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('nav-history-tab')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Riwayat tugas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-add-button')));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('task-title-input')), findsOneWidget);

    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Riwayat tugas'), findsOneWidget);
  });

  testWidgets('swipe right on active task opens edit sheet', (tester) async {
    final seededTask = buildTask(
      id: 'task-edit',
      title: 'Swipe Edit Target',
      dueAt: DateTime(2026, 2, 15, 11, 20),
    );

    await pumpHome(tester, seedTasks: <Task>[seededTask]);

    await tester.fling(
      find.byKey(const Key('task-dismiss-task-edit')),
      const Offset(900, 0),
      1400,
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const Key('task-title-input')), findsOneWidget);
  });

  testWidgets('swipe left on active task shows delete dialog and deletes task', (
    tester,
  ) async {
    final seededTask = buildTask(
      id: 'task-delete',
      title: 'Swipe Delete Target',
      dueAt: DateTime(2026, 2, 15, 11, 20),
    );

    await pumpHome(tester, seedTasks: <Task>[seededTask]);
    expect(find.byKey(const Key('task-card-task-delete')), findsOneWidget);

    await tester.fling(
      find.byKey(const Key('task-dismiss-task-delete')),
      const Offset(-900, 0),
      1400,
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('delete-task-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete-task-confirm-button')));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const Key('task-card-task-delete')), findsNothing);
  });

  testWidgets('history tab displays grouped completed tasks', (tester) async {
    final seededTasks = <Task>[
      buildTask(
        id: 'history-1',
        title: 'History One',
        dueAt: DateTime(2026, 2, 14, 12),
        createdAt: DateTime(2026, 2, 10, 9),
        isDone: true,
        completedAt: DateTime(2026, 2, 14, 18),
      ),
      buildTask(
        id: 'history-2',
        title: 'History Two',
        dueAt: DateTime(2026, 2, 14, 13),
        createdAt: DateTime(2026, 2, 10, 10),
        isDone: true,
        completedAt: DateTime(2026, 2, 14, 19),
      ),
    ];

    await pumpHome(tester, seedTasks: seededTasks);

    await tester.tap(find.byKey(const Key('nav-history-tab')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Riwayat tugas'), findsOneWidget);
    expect(find.byKey(const Key('history-date-card')), findsOneWidget);
    expect(find.byKey(const Key('history-task-card-history-1')), findsOneWidget);
    expect(find.byKey(const Key('history-task-card-history-2')), findsOneWidget);
  });

  testWidgets('history filter range updates displayed tasks', (tester) async {
    final seededTasks = <Task>[
      buildTask(
        id: 'history-a',
        title: 'History A',
        dueAt: DateTime(2026, 2, 14, 12),
        createdAt: DateTime(2026, 2, 10, 9),
        isDone: true,
        completedAt: DateTime(2026, 2, 14, 18),
      ),
      buildTask(
        id: 'history-b',
        title: 'History B',
        dueAt: DateTime(2026, 2, 14, 13),
        createdAt: DateTime(2026, 2, 12, 10),
        isDone: true,
        completedAt: DateTime(2026, 2, 14, 19),
      ),
    ];

    final container = await pumpHome(tester, seedTasks: seededTasks);

    await tester.tap(find.byKey(const Key('nav-history-tab')));
    await tester.pump(const Duration(milliseconds: 500));

    await container.read(historyControllerProvider.notifier).setDateRange(
      start: DateTime(2026, 2, 10),
      end: DateTime(2026, 2, 10),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('history-task-card-history-a')), findsOneWidget);
    expect(find.byKey(const Key('history-task-card-history-b')), findsNothing);
  });

  testWidgets('tap history task opens task detail sheet and does not restore', (
    tester,
  ) async {
    final seededTask = buildTask(
      id: 'history-undo',
      title: 'Undo Me',
      dueAt: DateTime(2026, 2, 14, 12),
      createdAt: DateTime(2026, 2, 10, 9),
      isDone: true,
      completedAt: DateTime(2026, 2, 14, 18),
    );

    await pumpHome(tester, seedTasks: <Task>[seededTask]);

    await tester.tap(find.byKey(const Key('nav-history-tab')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('history-task-card-history-undo')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('task-title-input')), findsOneWidget);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('history-task-card-history-undo')), findsOneWidget);
  });

  testWidgets('history restore button undoes completion and returns it to active tab', (
    tester,
  ) async {
    final seededTask = buildTask(
      id: 'history-undo',
      title: 'Undo Me',
      dueAt: DateTime(2026, 2, 14, 12),
      createdAt: DateTime(2026, 2, 10, 9),
      isDone: true,
      completedAt: DateTime(2026, 2, 14, 18),
    );

    await pumpHome(tester, seedTasks: <Task>[seededTask]);

    await tester.tap(find.byKey(const Key('nav-history-tab')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byKey(const Key('history-task-restore-history-undo')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('history-task-card-history-undo')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-active-tab')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('task-card-history-undo')), findsOneWidget);
  });

  testWidgets('history item supports swipe edit and delete', (tester) async {
    final seededTask = buildTask(
      id: 'history-actions',
      title: 'History Actions',
      dueAt: DateTime(2026, 2, 14, 12),
      createdAt: DateTime(2026, 2, 10, 9),
      isDone: true,
      completedAt: DateTime(2026, 2, 14, 18),
    );

    await pumpHome(tester, seedTasks: <Task>[seededTask]);

    await tester.tap(find.byKey(const Key('nav-history-tab')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.fling(
      find.byKey(const Key('history-task-dismiss-history-actions')),
      const Offset(900, 0),
      1400,
    );
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byKey(const Key('task-title-input')), findsOneWidget);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.fling(
      find.byKey(const Key('history-task-dismiss-history-actions')),
      const Offset(-900, 0),
      1400,
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('delete-task-dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete-task-confirm-button')));
    await tester.pump(const Duration(milliseconds: 700));

    expect(
      find.byKey(const Key('history-task-card-history-actions')),
      findsNothing,
    );
  });
}
