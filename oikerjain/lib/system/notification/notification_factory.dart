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

  String buildPayload(Task task) {
    return JsonCodecUtil.encode(<String, dynamic>{'taskId': task.id});
  }

  String? taskIdFromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = JsonCodecUtil.decode(payload);
      if (decoded is! Map) {
        return null;
      }
      final map = Map<String, dynamic>.from(decoded);
      return map['taskId']?.toString();
    } on FormatException {
      return null;
    }
  }
}
