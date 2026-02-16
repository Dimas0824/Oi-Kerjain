import '../model/task.dart';

abstract class TaskRepository {
  Future<List<Task>> getTasks();

  Future<List<Task>> getHistoryTasks({DateTime? start, DateTime? end});

  Future<void> upsertTask(Task task);

  Future<void> deleteTask(String taskId);

  Future<void> markDone(String taskId, {required bool isDone});

  Future<void> snoozeTask(String taskId, {Duration by = const Duration(minutes: 10)});

  Future<void> cleanupExpiredHistory();
}
