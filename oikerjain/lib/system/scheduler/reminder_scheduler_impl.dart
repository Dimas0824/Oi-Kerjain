import '../../domain/scheduler/reminder_scheduler.dart';
import '../../model/task.dart';
import '../notification/local_notification_service.dart';

class ReminderSchedulerImpl implements ReminderScheduler {
  const ReminderSchedulerImpl(this._notificationService);

  final LocalNotificationService _notificationService;

  @override
  Future<void> schedule(Task task) => _notificationService.scheduleTask(task);

  @override
  Future<void> cancel(String taskId) => _notificationService.cancelTask(taskId);

  @override
  Future<void> rescheduleAll(List<Task> tasks) async {
    for (final task in tasks) {
      if (!task.isDone) {
        await _notificationService.scheduleTask(task);
      }
    }
  }
}
