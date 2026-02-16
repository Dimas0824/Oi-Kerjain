import '../scheduler/reminder_scheduler.dart';
import '../task_repository.dart';

class DeleteTaskUseCase {
  const DeleteTaskUseCase(this._repository, this._scheduler);

  final TaskRepository _repository;
  final ReminderScheduler _scheduler;

  Future<void> call(String taskId) async {
    await _repository.deleteTask(taskId);
    await _scheduler.cancel(taskId);
  }
}
