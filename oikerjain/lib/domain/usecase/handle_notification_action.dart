import '../../core/constants/notification_const.dart';
import '../../core/time/clock.dart';
import '../../model/repeat_rule.dart';
import '../../model/task.dart';
import '../task_repository.dart';
import 'compute_next_occurrence.dart';
import 'mark_done.dart';
import 'snooze_task.dart';
import 'upsert_task.dart';

class HandleNotificationActionUseCase {
  HandleNotificationActionUseCase(
    this._repository,
    this._markDone,
    this._snoozeTask,
    this._upsertTask,
    this._computeNextOccurrence, {
    Clock? clock,
  }) : _clock = clock ?? const Clock();

  final TaskRepository _repository;
  final MarkDoneUseCase _markDone;
  final SnoozeTaskUseCase _snoozeTask;
  final UpsertTaskUseCase _upsertTask;
  final ComputeNextOccurrenceUseCase _computeNextOccurrence;
  final Clock _clock;

  Future<void> call({
    required String? taskId,
    required String? actionId,
  }) async {
    if (taskId == null || taskId.isEmpty) {
      return;
    }

    final task = await _findTask(taskId);
    if (task == null) {
      return;
    }

    if (actionId == NotificationConst.actionDone) {
      await _markDone(task, isDone: true);
      return;
    }

    final snoozeDuration = _resolveSnoozeDuration(actionId);
    if (snoozeDuration != null) {
      await _snoozeTask(task.id, by: snoozeDuration);
      return;
    }

    await _rollForwardRepeatIfOverdue(task);
  }

  Future<Task?> _findTask(String taskId) async {
    final tasks = await _repository.getTasks();
    for (final task in tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  Future<void> _rollForwardRepeatIfOverdue(Task task) async {
    if (task.isDone || task.repeatRule == RepeatRule.none) {
      return;
    }

    final nowMillis = _clock.now().millisecondsSinceEpoch;
    var nextDue = task.dueAtEpochMillis;

    while (nextDue <= nowMillis) {
      final nextOccurrence = _computeNextOccurrence(
        fromEpochMillis: nextDue,
        repeatRule: task.repeatRule,
      );
      if (nextOccurrence == null) {
        return;
      }
      nextDue = nextOccurrence;
    }

    if (nextDue == task.dueAtEpochMillis) {
      return;
    }

    await _upsertTask(
      task.copyWith(
        dueAtEpochMillis: nextDue,
        clearSnoozedUntilEpochMillis: true,
        updatedAtEpochMillis: nowMillis,
      ),
    );
  }

  Duration? _resolveSnoozeDuration(String? actionId) {
    switch (actionId) {
      case NotificationConst.actionSnooze1h:
        return const Duration(hours: 1);
      case NotificationConst.actionSnooze2h:
        return const Duration(hours: 2);
      case NotificationConst.actionSnooze4h:
        return const Duration(hours: 4);
      case NotificationConst.actionSnoozeCustom:
        return const Duration(hours: 1);
      case NotificationConst.actionSnooze10mLegacy:
        return const Duration(minutes: 10);
      default:
        return null;
    }
  }
}
