import '../../core/utils/json_codec.dart';
import '../../model/task.dart';
import '../../model/task_priority.dart';
import '../scheduler/reminder_plan.dart';

class NotificationFactory {
  const NotificationFactory();

  static const int _defaultCloseDeadlineLeadMillis = 60 * 60 * 1000;

  String buildTitle(Task task) =>
      '[${task.priority.label.toUpperCase()}] ${task.title}';

  String buildBody(
    Task task, {
    required ReminderKind reminderKind,
    int? scheduledAtEpochMillis,
  }) {
    final dueTimeLabel =
        '${task.dueAt.hour.toString().padLeft(2, '0')}:${task.dueAt.minute.toString().padLeft(2, '0')}';
    final description = task.description.trim();
    switch (reminderKind) {
      case ReminderKind.closeDeadline:
        final closeReminderAtEpochMillis =
            scheduledAtEpochMillis ??
            (task.dueAtEpochMillis - _defaultCloseDeadlineLeadMillis);
        final remainingLabel = _formatRemainingTimeLabel(
          task.dueAtEpochMillis - closeReminderAtEpochMillis,
        );
        if (description.isNotEmpty) {
          return remainingLabel == 'sekarang'
              ? 'Deadline sekarang. $description'
              : 'Deadline $remainingLabel lagi. $description';
        }
        return remainingLabel == 'sekarang'
            ? 'Deadline pada $dueTimeLabel (sekarang).'
            : 'Deadline pada $dueTimeLabel ($remainingLabel lagi).';
      case ReminderKind.overdue:
        if (description.isNotEmpty) {
          return 'Task sudah lewat deadline. $description';
        }
        return 'Task sudah lewat deadline sejak $dueTimeLabel.';
    }
  }

  String _formatRemainingTimeLabel(int remainingMillis) {
    if (remainingMillis <= 0) {
      return 'sekarang';
    }

    final totalMinutes = (remainingMillis / Duration.millisecondsPerMinute)
        .ceil();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours jam $minutes menit';
    }
    if (hours > 0) {
      return '$hours jam';
    }
    return '$minutes menit';
  }

  String buildUpcomingSummaryTitle(int taskCount) {
    return taskCount == 1
        ? '1 tugas deadline <= 3 hari'
        : '$taskCount tugas deadline <= 3 hari';
  }

  String buildUpcomingSummaryBody(List<Task> tasks) {
    if (tasks.isEmpty) {
      return 'Ada tugas dengan deadline dekat.';
    }

    final sorted = List<Task>.from(tasks)
      ..sort((a, b) => a.dueAtEpochMillis.compareTo(b.dueAtEpochMillis));
    final nearest = sorted.first;
    final nearestDue =
        '${nearest.dueAt.day.toString().padLeft(2, '0')}/${nearest.dueAt.month.toString().padLeft(2, '0')} ${nearest.dueAt.hour.toString().padLeft(2, '0')}:${nearest.dueAt.minute.toString().padLeft(2, '0')}';
    if (sorted.length == 1) {
      return 'Cek "${nearest.title}" sebelum $nearestDue.';
    }
    return 'Terdekat: "${nearest.title}" pada $nearestDue.';
  }

  String buildPayload(
    Task task, {
    required int scheduledAtEpochMillis,
    required ReminderKind reminderKind,
  }) {
    return JsonCodecUtil.encode(<String, dynamic>{
      'taskId': task.id,
      'scheduledAtEpochMillis': scheduledAtEpochMillis,
      'reminderKind': reminderKind.name,
      'isCloseDeadline': reminderKind == ReminderKind.closeDeadline,
    });
  }

  String buildUpcomingSummaryPayload({
    required int scheduledAtEpochMillis,
    required List<String> taskIds,
  }) {
    return JsonCodecUtil.encode(<String, dynamic>{
      'scheduledAtEpochMillis': scheduledAtEpochMillis,
      'reminderKind': 'upcomingSummary',
      'summaryTaskIds': taskIds,
    });
  }

  String? taskIdFromPayload(String? payload) {
    final parsed = parsePayload(payload);
    return parsed?.taskId;
  }

  NotificationPayload? parsePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = JsonCodecUtil.decode(payload);
      if (decoded is! Map) {
        return null;
      }
      final map = Map<String, dynamic>.from(decoded);
      final taskId = map['taskId']?.toString();
      final normalizedTaskId = taskId == null || taskId.trim().isEmpty
          ? null
          : taskId;
      final summaryTaskIds =
          (map['summaryTaskIds'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .toList(growable: false) ??
          const <String>[];

      if (normalizedTaskId == null && summaryTaskIds.isEmpty) {
        return null;
      }

      final reminderKind = _reminderKindFromPayload(map);
      final legacyIsCloseDeadline = map['isCloseDeadline'] == true;

      return NotificationPayload(
        taskId: normalizedTaskId,
        summaryTaskIds: summaryTaskIds,
        scheduledAtEpochMillis: (map['scheduledAtEpochMillis'] as num?)
            ?.toInt(),
        reminderKind: reminderKind,
        isCloseDeadline:
            reminderKind == ReminderKind.closeDeadline || legacyIsCloseDeadline,
      );
    } on FormatException {
      return null;
    }
  }

  ReminderKind? _reminderKindFromPayload(Map<String, dynamic> map) {
    final rawReminderKind = map['reminderKind']?.toString();
    if (rawReminderKind == null || rawReminderKind.trim().isEmpty) {
      return null;
    }

    for (final kind in ReminderKind.values) {
      if (kind.name == rawReminderKind) {
        return kind;
      }
    }

    return null;
  }
}

class NotificationPayload {
  const NotificationPayload({
    this.taskId,
    this.summaryTaskIds = const <String>[],
    this.scheduledAtEpochMillis,
    this.reminderKind,
    this.isCloseDeadline = false,
  });

  final String? taskId;
  final List<String> summaryTaskIds;
  final int? scheduledAtEpochMillis;
  final ReminderKind? reminderKind;
  final bool isCloseDeadline;
}
