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

  Future<void> pumpHome(
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
  }

  testWidgets('home renders new command layout', (tester) async {
    await pumpHome(tester);

    expect(find.text('Tugas aktif'), findsOneWidget);
    expect(find.text('Belum ada tugas yang cocok.'), findsOneWidget);
    expect(find.byKey(const Key('search-input')), findsOneWidget);
  });

  testWidgets('category filter can be tapped', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('filter-personal')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Belum ada tugas yang cocok.'), findsOneWidget);
  });

  testWidgets('search filters task list', (tester) async {
    final seededTasks = <Task>[
      Task(
        id: 'task-search-1',
        title: 'System Architecture',
        dueAtEpochMillis: DateTime(2026, 2, 15, 11).millisecondsSinceEpoch,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.high,
        category: TaskCategory.work,
        isDone: false,
        updatedAtEpochMillis: fixedClock.now().millisecondsSinceEpoch,
      ),
      Task(
        id: 'task-search-2',
        title: 'Car Service',
        dueAtEpochMillis: DateTime(2026, 2, 15, 12).millisecondsSinceEpoch,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.medium,
        category: TaskCategory.personal,
        isDone: false,
        updatedAtEpochMillis: fixedClock.now().millisecondsSinceEpoch,
      ),
    ];

    await pumpHome(tester, seedTasks: seededTasks);

    await tester.enterText(find.byKey(const Key('search-input')), 'car');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('task-card-task-search-2')), findsOneWidget);
    expect(find.byKey(const Key('task-card-task-search-1')), findsNothing);
  });

  testWidgets('tap task card toggles done status', (tester) async {
    final seededTask = Task(
      id: 'task-1',
      title: 'Task Toggle',
      dueAtEpochMillis: DateTime(2026, 2, 15, 11, 20).millisecondsSinceEpoch,
      repeatRule: RepeatRule.none,
      priority: TaskPriority.medium,
      category: TaskCategory.work,
      isDone: false,
      updatedAtEpochMillis: fixedClock.now().millisecondsSinceEpoch,
    );

    await pumpHome(tester, seedTasks: <Task>[seededTask]);

    expect(find.byKey(const Key('task-card-task-1')), findsOneWidget);
    expect(find.byKey(const Key('task-check-icon-task-1')), findsNothing);

    await tester.tap(find.byKey(const Key('task-card-task-1')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('task-check-icon-task-1')), findsOneWidget);
  });

  testWidgets('add flow from bottom sheet creates task', (tester) async {
    await pumpHome(tester);

    await tester.ensureVisible(find.byKey(const Key('fab-add-task')));
    await tester.tap(
      find.byKey(const Key('fab-add-task')),
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
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Task From Widget Test'), findsOneWidget);
  });

  testWidgets('swipe right opens edit sheet', (tester) async {
    final seededTask = Task(
      id: 'task-edit',
      title: 'Swipe Edit Target',
      dueAtEpochMillis: DateTime(2026, 2, 15, 11, 20).millisecondsSinceEpoch,
      repeatRule: RepeatRule.none,
      priority: TaskPriority.medium,
      category: TaskCategory.work,
      isDone: false,
      updatedAtEpochMillis: fixedClock.now().millisecondsSinceEpoch,
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

  testWidgets('swipe left shows delete confirmation and deletes task', (
    tester,
  ) async {
    final seededTask = Task(
      id: 'task-delete',
      title: 'Swipe Delete Target',
      dueAtEpochMillis: DateTime(2026, 2, 15, 11, 20).millisecondsSinceEpoch,
      repeatRule: RepeatRule.none,
      priority: TaskPriority.medium,
      category: TaskCategory.work,
      isDone: false,
      updatedAtEpochMillis: fixedClock.now().millisecondsSinceEpoch,
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
}
