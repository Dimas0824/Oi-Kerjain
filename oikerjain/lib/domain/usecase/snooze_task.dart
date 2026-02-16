import '../../model/task.dart';
import '../scheduler/reminder_scheduler.dart';
import '../task_repository.dart';

class SnoozeTaskUseCase {
  const SnoozeTaskUseCase(this._repository, this._scheduler);

  final TaskRepository _repository;
  final ReminderScheduler _scheduler;

  Future<void> call(String taskId, {Duration by = const Duration(minutes: 10)}) async {
    await _repository.snoozeTask(taskId, by: by);
    final tasks = await _repository.getTasks();

    Task? target;
    for (final task in tasks) {
      if (task.id == taskId) {
        target = task;
        break;
      }
    }

    if (target == null || target.isDone) {
      return;
    }

    await _scheduler.schedule(target);
  }
}
