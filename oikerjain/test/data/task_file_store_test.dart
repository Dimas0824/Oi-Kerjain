import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oikerjain/data/local/task_file_store.dart';
import 'package:oikerjain/model/repeat_rule.dart';
import 'package:oikerjain/model/task.dart';
import 'package:oikerjain/model/task_category.dart';
import 'package:oikerjain/model/task_priority.dart';

void main() {
  group('TaskFileStore', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('oikerjain_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    TaskFileStore createStore() {
      return TaskFileStore(directoryProvider: () async => tempDir);
    }

    Task sampleTask({
      required String id,
      required int dueAtMillis,
      String title = 'Task',
    }) {
      return Task(
        id: id,
        title: title,
        createdAtEpochMillis: dueAtMillis,
        dueAtEpochMillis: dueAtMillis,
        repeatRule: RepeatRule.none,
        priority: TaskPriority.medium,
        category: TaskCategory.work,
        isDone: false,
        completedAtEpochMillis: null,
        updatedAtEpochMillis: dueAtMillis,
      );
    }

    test('writes and reads tasks from tasks.json', () async {
      final store = createStore();
      final tasks = <Task>[
        sampleTask(
          id: 'task-1',
          dueAtMillis: DateTime(2026, 2, 15, 10).millisecondsSinceEpoch,
        ),
      ];

      await store.writeAll(tasks);
      final loaded = await store.readAll();

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'task-1');
      expect(loaded.single.title, 'Task');
    });

    test('returns empty list for corrupt json', () async {
      final file = File('${tempDir.path}/tasks.json');
      await file.writeAsString('{invalid-json', flush: true);

      final store = createStore();
      final loaded = await store.readAll();

      expect(loaded, isEmpty);
    });

    test('overwrites existing file using atomic temp file', () async {
      final store = createStore();
      await store.writeAll(<Task>[
        sampleTask(
          id: 'task-old',
          dueAtMillis: DateTime(2026, 2, 15, 10).millisecondsSinceEpoch,
        ),
      ]);

      await store.writeAll(<Task>[
        sampleTask(
          id: 'task-new',
          dueAtMillis: DateTime(2026, 2, 16, 10).millisecondsSinceEpoch,
        ),
      ]);

      final loaded = await store.readAll();
      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'task-new');
      expect(File('${tempDir.path}/tasks.json.tmp').existsSync(), isFalse);
    });
  });
}
