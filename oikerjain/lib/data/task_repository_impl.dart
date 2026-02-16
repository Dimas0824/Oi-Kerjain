import '../core/time/clock.dart';
import '../domain/task_repository.dart';
import '../model/task.dart';
import '../model/task_priority.dart';
import 'local/task_store.dart';

class TaskRepositoryImpl implements TaskRepository {
  static const Duration _historyRetention = Duration(days: 14);

  TaskRepositoryImpl(this._store, {Clock? clock}) : _clock = clock ?? const Clock();

  final TaskStore _store;
  final Clock _clock;

  @override
  Future<List<Task>> getTasks() async {
    final tasks = await _loadAndCleanup();
    final todayBoundary = _resolveTodayBoundary();
    final active = tasks
        .where((task) => _isTaskForActiveHome(task, todayBoundary))
        .toList()
      ..sort(_sortTask);
    return active;
  }

  @override
  Future<List<Task>> getHistoryTasks({DateTime? start, DateTime? end}) async {
    final tasks = await _loadAndCleanup();
    final todayBoundary = _resolveTodayBoundary();

    final history = tasks
        .where((task) => _isHistoryTask(task, todayBoundary))
        .where((task) => _isWithinCreatedRange(task, start: start, end: end))
        .toList()
      ..sort(_sortHistoryTask);
    return history;
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
          completedAtEpochMillis: isDone ? nowMillis : null,
          clearCompletedAtEpochMillis: !isDone,
          clearSnoozedUntilEpochMillis: true,
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
        final snoozedUntil = nowMillis + by.inMilliseconds;
        final clampedSnoozedUntil = snoozedUntil > current.dueAtEpochMillis
            ? current.dueAtEpochMillis
            : snoozedUntil;
        tasks[i] = current.copyWith(
          snoozedUntilEpochMillis: clampedSnoozedUntil,
          updatedAtEpochMillis: nowMillis,
        );
        break;
      }
    }

    await _store.writeAll(tasks);
  }

  @override
  Future<void> cleanupExpiredHistory() async {
    await _loadAndCleanup();
  }

  Future<List<Task>> _loadAndCleanup() async {
    final nowMillis = _clock.now().millisecondsSinceEpoch;
    final historyCutoff = nowMillis - _historyRetention.inMilliseconds;
    final tasks = List<Task>.from(await _store.readAll());

    final cleaned = tasks
        .where((task) => !_isHistoryExpired(task, historyCutoff))
        .toList();

    if (cleaned.length != tasks.length) {
      await _store.writeAll(cleaned);
    }

    return cleaned;
  }

  bool _isHistoryExpired(Task task, int historyCutoff) {
    if (!task.isDone) {
      return false;
    }

    final completedAt = task.completedAtEpochMillis;
    if (completedAt == null) {
      return false;
    }

    return completedAt < historyCutoff;
  }

  bool _isWithinCreatedRange(Task task, {DateTime? start, DateTime? end}) {
    final createdAt = task.createdAt;
    if (start != null) {
      final startOfDay = DateTime(start.year, start.month, start.day);
      if (createdAt.isBefore(startOfDay)) {
        return false;
      }
    }

    if (end != null) {
      final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
      if (createdAt.isAfter(endOfDay)) {
        return false;
      }
    }

    return true;
  }

  _TodayBoundary _resolveTodayBoundary() {
    final now = _clock.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return _TodayBoundary(
      todayStartEpochMillis: todayStart.millisecondsSinceEpoch,
      todayEndEpochMillis: todayEnd.millisecondsSinceEpoch,
    );
  }

  bool _isTaskForActiveHome(Task task, _TodayBoundary todayBoundary) {
    if (!task.isDone) {
      return true;
    }

    final completedAt = task.completedAtEpochMillis;
    if (completedAt == null) {
      return true;
    }

    if (_isCompletedToday(completedAt, todayBoundary)) {
      return true;
    }

    return completedAt > todayBoundary.todayEndEpochMillis;
  }

  bool _isHistoryTask(Task task, _TodayBoundary todayBoundary) {
    if (!task.isDone) {
      return false;
    }

    final completedAt = task.completedAtEpochMillis;
    if (completedAt == null) {
      return false;
    }

    return completedAt < todayBoundary.todayStartEpochMillis;
  }

  bool _isCompletedToday(int completedAt, _TodayBoundary todayBoundary) {
    return completedAt >= todayBoundary.todayStartEpochMillis &&
        completedAt <= todayBoundary.todayEndEpochMillis;
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

  int _sortHistoryTask(Task a, Task b) {
    final createdCompare = b.createdAtEpochMillis.compareTo(a.createdAtEpochMillis);
    if (createdCompare != 0) {
      return createdCompare;
    }

    final completedCompare =
        (b.completedAtEpochMillis ?? 0).compareTo(a.completedAtEpochMillis ?? 0);
    if (completedCompare != 0) {
      return completedCompare;
    }

    return b.updatedAtEpochMillis.compareTo(a.updatedAtEpochMillis);
  }
}

class _TodayBoundary {
  const _TodayBoundary({
    required this.todayStartEpochMillis,
    required this.todayEndEpochMillis,
  });

  final int todayStartEpochMillis;
  final int todayEndEpochMillis;
}
