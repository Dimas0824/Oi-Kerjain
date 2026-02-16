import '../core/time/clock.dart';
import '../domain/task_repository.dart';
import '../model/task.dart';
import '../model/task_priority.dart';
import 'local/task_store.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._store, {Clock? clock}) : _clock = clock ?? const Clock();

  final TaskStore _store;
  final Clock _clock;

  @override
  Future<List<Task>> getTasks() async {
    final tasks = List<Task>.from(await _store.readAll());
    tasks.sort(_sortTask);
    return tasks;
  }

  @override
  Future<void> upsertTask(Task task) async {
    final tasks = List<Task>.from(await _store.readAll());
    final index = tasks.indexWhere((item) => item.id == task.id);

    if (index == -1) {
      tasks.insert(0, task);
    } else {
      tasks[index] = task;
    }

    await _store.writeAll(tasks);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    final tasks = List<Task>.from(await _store.readAll())
      ..removeWhere((item) => item.id == taskId);
    await _store.writeAll(tasks);
  }

  @override
  Future<void> markDone(String taskId, {required bool isDone}) async {
    final nowMillis = _clock.now().millisecondsSinceEpoch;
    final tasks = List<Task>.from(await _store.readAll());

    for (var i = 0; i < tasks.length; i++) {
      final current = tasks[i];
      if (current.id == taskId) {
        tasks[i] = current.copyWith(
          isDone: isDone,
          updatedAtEpochMillis: nowMillis,
        );
        break;
      }
    }

    await _store.writeAll(tasks);
  }

  @override
  Future<void> snoozeTask(String taskId, {Duration by = const Duration(minutes: 10)}) async {
    final nowMillis = _clock.now().millisecondsSinceEpoch;
    final tasks = List<Task>.from(await _store.readAll());

    for (var i = 0; i < tasks.length; i++) {
      final current = tasks[i];
      if (current.id == taskId) {
        tasks[i] = current.copyWith(
          dueAtEpochMillis: current.dueAtEpochMillis + by.inMilliseconds,
          updatedAtEpochMillis: nowMillis,
        );
        break;
      }
    }

    await _store.writeAll(tasks);
  }

  int _sortTask(Task a, Task b) {
    final priorityCompare = b.priority.rank.compareTo(a.priority.rank);
    if (priorityCompare != 0) {
      return priorityCompare;
    }

    final dueCompare = a.dueAtEpochMillis.compareTo(b.dueAtEpochMillis);
    if (dueCompare != 0) {
      return dueCompare;
    }

    return b.updatedAtEpochMillis.compareTo(a.updatedAtEpochMillis);
  }
}
