import '../../model/task.dart';
import '../scheduler/reminder_scheduler.dart';
import '../task_repository.dart';

class MarkDoneUseCase {
  const MarkDoneUseCase(this._repository, this._scheduler);

  final TaskRepository _repository;
  final ReminderScheduler _scheduler;

  Future<void> call(Task task, {required bool isDone}) async {
    await _repository.markDone(task.id, isDone: isDone);
    try {
      final tasks = await _repository.getTasks();
      await _scheduler.rescheduleAll(tasks);
    } catch (_) {
      // Persisting task status is the primary operation.
      // Notification scheduling/cancel failures should not break UI updates.
    }
  }
}
