import '../../domain/scheduler/reminder_scheduler.dart';
import '../../core/time/clock.dart';
import '../../model/task.dart';
import '../notification/local_notification_service.dart';
import 'reminder_plan.dart';

class ReminderSchedulerImpl implements ReminderScheduler {
  ReminderSchedulerImpl(
    this._notificationService, {
    ReminderPlanBuilder? reminderPlanBuilder,
    Clock? clock,
  }) : _reminderPlanBuilder =
           reminderPlanBuilder ?? const ReminderPlanBuilder(),
       _clock = clock ?? const Clock();

  final LocalNotificationService _notificationService;
  final ReminderPlanBuilder _reminderPlanBuilder;
  final Clock _clock;

  @override
  Future<void> schedule(Task task) async {
    if (task.isDone) {
      await _notificationService.cancelTask(task.id);
      return;
    }

    final plan = _reminderPlanBuilder.build(task: task, now: _clock.now());
    await _notificationService.scheduleTaskReminders(task, plan);
  }

  @override
  Future<void> cancel(String taskId) => _notificationService.cancelTask(taskId);

  @override
  Future<void> rescheduleAll(List<Task> tasks) async {
    for (final task in tasks) {
      if (task.isDone) {
        await cancel(task.id);
        continue;
      }
      await schedule(task);
    }
  }
}
