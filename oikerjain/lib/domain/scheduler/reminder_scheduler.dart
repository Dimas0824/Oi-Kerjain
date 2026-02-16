import '../../model/task.dart';

abstract class ReminderScheduler {
  Future<void> schedule(Task task);

  Future<void> cancel(String taskId);

  Future<void> rescheduleAll(List<Task> tasks);
}
