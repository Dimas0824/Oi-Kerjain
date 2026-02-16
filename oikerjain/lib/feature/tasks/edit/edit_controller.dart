import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../../../core/time/clock.dart';
import '../../../core/utils/id.dart';
import '../../../domain/usecase/upsert_task.dart';
import '../../../model/task.dart';
import '../../../model/task_category.dart';
import '../../../model/task_priority.dart';
import '../../../model/repeat_rule.dart';
import 'edit_state.dart';

class EditController extends legacy.StateNotifier<EditState> {
  EditController({
    required UpsertTaskUseCase upsertTask,
    required IdGenerator idGenerator,
    required Clock clock,
    Task? initialTask,
  }) : _upsertTask = upsertTask,
       _idGenerator = idGenerator,
       _clock = clock,
       super(_fromInitialTask(initialTask));

  final UpsertTaskUseCase _upsertTask;
  final IdGenerator _idGenerator;
  final Clock _clock;

  void setTitle(String value) {
    state = state.copyWith(title: value, clearError: true);
  }

  void setDescription(String value) {
    state = state.copyWith(description: value, clearError: true);
  }

  void setDueDateText(String value) {
    state = state.copyWith(dueDateText: value, clearError: true);
  }

  void setDueTimeText(String value) {
    state = state.copyWith(dueTimeText: value, clearError: true);
  }

  void setRepeatRule(RepeatRule value) {
    state = state.copyWith(repeatRule: value, clearError: true);
  }

  void setCategory(TaskCategory value) {
    state = state.copyWith(category: value, clearError: true);
  }

  void setPriority(TaskPriority value) {
    state = state.copyWith(priority: value, clearError: true);
  }

  Future<bool> submit() async {
    final title = state.title.trim();
    if (title.isEmpty) {
      state = state.copyWith(errorMessage: 'Judul tugas wajib diisi.');
      return false;
    }

    final dueDate = _parseDate(state.dueDateText, fallback: _clock.now());
    if (dueDate == null) {
      state = state.copyWith(
        errorMessage: 'Format tanggal tenggat tidak valid.',
      );
      return false;
    }

    final dueTime = _parseTime(state.dueTimeText);
    if (dueTime == null) {
      state = state.copyWith(errorMessage: 'Format waktu tidak valid.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final now = _clock.now();
      final dueAt = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        dueTime.hour,
        dueTime.minute,
      );
      final source = state.editingTask;

      final task = Task(
        id: source?.id ?? _idGenerator.newId(),
        title: title,
        description: state.description.trim(),
        dueAtEpochMillis: dueAt.millisecondsSinceEpoch,
        repeatRule: state.repeatRule,
        priority: state.priority,
        category: state.category,
        isDone: source?.isDone ?? false,
        updatedAtEpochMillis: now.millisecondsSinceEpoch,
      );

      await _upsertTask(task);
      state = state.copyWith(isSubmitting: false, clearError: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Tugas gagal disimpan. Coba lagi.',
      );
      return false;
    }
  }

  static EditState _fromInitialTask(Task? task) {
    if (task == null) {
      return const EditState();
    }

    final dueAt = task.dueAt;
    return EditState(
      editingTask: task,
      title: task.title,
      description: task.description,
      dueDateText:
          '${dueAt.day.toString().padLeft(2, '0')}-${dueAt.month.toString().padLeft(2, '0')}-${dueAt.year.toString().padLeft(4, '0')}',
      dueTimeText: '${dueAt.hour.toString().padLeft(2, '0')}:00',
      repeatRule: task.repeatRule,
      category: task.category,
      priority: task.priority,
    );
  }

  DateTime? _parseDate(String raw, {required DateTime fallback}) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return DateTime(fallback.year, fallback.month, fallback.day);
    }

    final dmyMatch = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(clean);
    final ymdMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(clean);
    if (dmyMatch == null && ymdMatch == null) {
      return null;
    }

    final year = int.tryParse((dmyMatch?.group(3) ?? ymdMatch?.group(1)) ?? '');
    final month = int.tryParse(
      (dmyMatch?.group(2) ?? ymdMatch?.group(2)) ?? '',
    );
    final day = int.tryParse((dmyMatch?.group(1) ?? ymdMatch?.group(3)) ?? '');
    if (year == null || month == null || day == null) {
      return null;
    }

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  ({int hour, int minute})? _parseTime(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return (hour: 12, minute: 0);
    }

    final match = RegExp(r'^(\d{1,2})(?::(\d{2}))?$').firstMatch(clean);
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '0');
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return (hour: hour, minute: minute);
  }
}
