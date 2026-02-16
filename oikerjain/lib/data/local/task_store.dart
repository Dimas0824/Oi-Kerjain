import '../../model/task.dart';

abstract class TaskStore {
  Future<List<Task>> readAll();

  Future<void> writeAll(List<Task> tasks);
}
