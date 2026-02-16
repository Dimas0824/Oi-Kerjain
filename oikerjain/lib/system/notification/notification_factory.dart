import '../../core/utils/json_codec.dart';
import '../../model/task.dart';
import '../../model/task_priority.dart';

class NotificationFactory {
  const NotificationFactory();

  String buildTitle(Task task) =>
      '[${task.priority.label.toUpperCase()}] ${task.title}';

  String buildBody(Task task) {
    final description = task.description.trim();
    if (description.isNotEmpty) {
      return description;
    }
    return 'Dijadwalkan pada ${task.dueAt.hour.toString().padLeft(2, '0')}:${task.dueAt.minute.toString().padLeft(2, '0')}';
  }

  String buildPayload(
    Task task, {
    required int scheduledAtEpochMillis,
    required bool isCloseDeadline,
  }) {
    return JsonCodecUtil.encode(<String, dynamic>{
      'taskId': task.id,
      'scheduledAtEpochMillis': scheduledAtEpochMillis,
      'isCloseDeadline': isCloseDeadline,
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
      if (taskId == null || taskId.trim().isEmpty) {
        return null;
      }
      return NotificationPayload(
        taskId: taskId,
        scheduledAtEpochMillis: (map['scheduledAtEpochMillis'] as num?)?.toInt(),
        isCloseDeadline: map['isCloseDeadline'] == true,
      );
    } on FormatException {
      return null;
    }
  }
}

class NotificationPayload {
  const NotificationPayload({
    required this.taskId,
    this.scheduledAtEpochMillis,
    this.isCloseDeadline = false,
  });

  final String taskId;
  final int? scheduledAtEpochMillis;
  final bool isCloseDeadline;
}
