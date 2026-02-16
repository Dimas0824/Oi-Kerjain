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
      if (isDone) {
        await _scheduler.cancel(task.id);
        return;
      }
      await _scheduler.schedule(task.copyWith(isDone: false));
    } catch (_) {
      // Persisting task status is the primary operation.
      // Notification scheduling/cancel failures should not break UI updates.
    }
  }
}
