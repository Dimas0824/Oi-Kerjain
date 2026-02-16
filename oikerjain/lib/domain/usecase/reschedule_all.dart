import '../../core/time/clock.dart';
import '../../model/repeat_rule.dart';
import '../../model/task.dart';
import '../scheduler/reminder_scheduler.dart';
import '../task_repository.dart';
import 'compute_next_occurrence.dart';

class RescheduleAllUseCase {
  RescheduleAllUseCase(
    this._repository,
    this._scheduler,
    this._computeNextOccurrence, {
    Clock? clock,
  }) : _clock = clock ?? const Clock();

  final TaskRepository _repository;
  final ReminderScheduler _scheduler;
  final ComputeNextOccurrenceUseCase _computeNextOccurrence;
  final Clock _clock;

  Future<void> call() async {
    final nowMillis = _clock.now().millisecondsSinceEpoch;
    final tasks = await _repository.getTasks();
    final reschedulable = <Task>[];

    for (final task in tasks) {
      if (task.isDone) {
        continue;
      }

      var candidate = task;
      if (task.repeatRule != RepeatRule.none) {
        var dueAtMillis = task.dueAtEpochMillis;
        while (dueAtMillis <= nowMillis) {
          final next = _computeNextOccurrence(
            fromEpochMillis: dueAtMillis,
            repeatRule: task.repeatRule,
          );
          if (next == null) {
            break;
          }
          dueAtMillis = next;
        }

        if (dueAtMillis != task.dueAtEpochMillis) {
          candidate = task.copyWith(
            dueAtEpochMillis: dueAtMillis,
            clearSnoozedUntilEpochMillis: true,
            updatedAtEpochMillis: nowMillis,
          );
          await _repository.upsertTask(candidate);
        }
      }

      if (candidate.dueAtEpochMillis >= nowMillis) {
        reschedulable.add(candidate);
      }
    }

    await _scheduler.rescheduleAll(reschedulable);
  }
}
