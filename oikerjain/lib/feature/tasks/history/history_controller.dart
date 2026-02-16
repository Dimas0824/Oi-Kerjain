import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../../../core/time/clock.dart';
import '../../../domain/usecase/delete_task.dart';
import '../../../domain/usecase/get_history_tasks.dart';
import '../../../domain/usecase/mark_done.dart';
import '../../../model/task.dart';
import 'history_state.dart';

class HistoryController extends legacy.StateNotifier<HistoryState> {
  HistoryController({
    required GetHistoryTasksUseCase getHistoryTasks,
    required MarkDoneUseCase markDone,
    required DeleteTaskUseCase deleteTask,
    required Clock clock,
  }) : _getHistoryTasks = getHistoryTasks,
       _markDone = markDone,
       _deleteTask = deleteTask,
       _clock = clock,
       super(
         HistoryState(
           isLoading: true,
           filterMode: HistoryFilterMode.weekly,
           weekStartDate: _mondayOf(clock.now()),
         ),
       ) {
    _loadHistory();
  }

  final GetHistoryTasksUseCase _getHistoryTasks;
  final MarkDoneUseCase _markDone;
  final DeleteTaskUseCase _deleteTask;
  final Clock _clock;

  Future<void> refresh() => _loadHistory();

  Future<void> setDateRange({required DateTime start, required DateTime end}) async {
    final normalizedStart = _dateOnly(start);
    final normalizedEnd = _dateOnly(end);
    if (normalizedStart.isAfter(normalizedEnd)) {
      state = state.copyWith(
        filterMode: HistoryFilterMode.custom,
        customStartDate: normalizedEnd,
        customEndDate: normalizedStart,
      );
    } else {
      state = state.copyWith(
        filterMode: HistoryFilterMode.custom,
        customStartDate: normalizedStart,
        customEndDate: normalizedEnd,
      );
    }
    await _loadHistory();
  }

  Future<void> showPreviousWeek() async {
    state = state.copyWith(
      filterMode: HistoryFilterMode.weekly,
      weekStartDate: _dateOnly(state.weekStartDate.subtract(const Duration(days: 7))),
    );
    await _loadHistory();
  }

  Future<void> showNextWeek() async {
    state = state.copyWith(
      filterMode: HistoryFilterMode.weekly,
      weekStartDate: _dateOnly(state.weekStartDate.add(const Duration(days: 7))),
    );
    await _loadHistory();
  }

  Future<void> clearDateRange() => resetToCurrentWeek();

  Future<void> resetToCurrentWeek() async {
    state = state.copyWith(
      filterMode: HistoryFilterMode.weekly,
      weekStartDate: _mondayOf(_clock.now()),
      clearCustomStartDate: true,
      clearCustomEndDate: true,
    );
    await _loadHistory();
  }

  Future<void> undoDone(String taskId) async {
    final target = _findTaskById(taskId);
    if (target == null) {
      return;
    }

    try {
      await _markDone(target, isDone: false);
      await _loadHistory();
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Status tugas gagal diperbarui. Coba lagi.',
      );
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _deleteTask(taskId);
      await _loadHistory();
    } catch (_) {
      state = state.copyWith(errorMessage: 'Tugas gagal dihapus. Coba lagi.');
    }
  }

  Task? _findTaskById(String taskId) {
    for (final task in state.tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  Future<void> _loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tasks = await _getHistoryTasks(
        start: state.effectiveStartDate,
        end: state.effectiveEndDate,
      );
      state = state.copyWith(tasks: tasks, isLoading: false, clearError: true);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Riwayat tugas gagal dimuat. Coba lagi.',
      );
    }
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime _mondayOf(DateTime value) {
    final normalized = _dateOnly(value);
    return normalized.subtract(Duration(days: normalized.weekday - DateTime.monday));
  }
}
