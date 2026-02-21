import 'dart:developer' as developer;

import '../../model/task.dart';
import '../scheduler/reminder_scheduler.dart';
import '../task_repository.dart';

class UpsertTaskUseCase {
  const UpsertTaskUseCase(this._repository, this._scheduler);

  final TaskRepository _repository;
  final ReminderScheduler _scheduler;

  Future<void> call(Task task) async {
    await _repository.upsertTask(task);
    try {
      final tasks = await _repository.getTasks();
      await _scheduler.rescheduleAll(tasks);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to reschedule notifications after upsert for task ${task.id}',
        name: 'oikerjain.scheduler',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
