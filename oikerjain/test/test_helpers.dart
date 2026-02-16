import 'package:oikerjain/core/time/clock.dart';
import 'package:oikerjain/domain/scheduler/reminder_scheduler.dart';
import 'package:oikerjain/model/task.dart';

class FixedClock extends Clock {
  const FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}

class FakeReminderScheduler implements ReminderScheduler {
  @override
  Future<void> cancel(String taskId) async {}

  @override
  Future<void> rescheduleAll(List<Task> tasks) async {}

  @override
  Future<void> schedule(Task task) async {}
}
