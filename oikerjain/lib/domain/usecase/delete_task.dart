import '../scheduler/reminder_scheduler.dart';
import '../task_repository.dart';

class DeleteTaskUseCase {
  const DeleteTaskUseCase(this._repository, this._scheduler);

  final TaskRepository _repository;
  final ReminderScheduler _scheduler;

  Future<void> call(String taskId) async {
    await _repository.deleteTask(taskId);
    try {
      await _scheduler.cancel(taskId);
    } catch (_) {
      // Persisting task deletion is the primary operation.
      // Notification cancel failures should not block UI updates.
    }

    try {
      final tasks = await _repository.getTasks();
      await _scheduler.rescheduleAll(tasks);
    } catch (_) {
      // Persisting task deletion is the primary operation.
      // Notification scheduling failures should not block UI updates.
    }
  }
}
