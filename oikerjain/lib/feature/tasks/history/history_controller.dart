import 'package:flutter_riverpod/legacy.dart' as legacy;

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
  }) : _getHistoryTasks = getHistoryTasks,
       _markDone = markDone,
       _deleteTask = deleteTask,
       super(const HistoryState(isLoading: true)) {
    _loadHistory();
  }

  final GetHistoryTasksUseCase _getHistoryTasks;
  final MarkDoneUseCase _markDone;
  final DeleteTaskUseCase _deleteTask;

  Future<void> refresh() => _loadHistory();

  Future<void> setDateRange({required DateTime start, required DateTime end}) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    if (normalizedStart.isAfter(normalizedEnd)) {
      state = state.copyWith(startDate: normalizedEnd, endDate: normalizedStart);
    } else {
      state = state.copyWith(startDate: normalizedStart, endDate: normalizedEnd);
    }
    await _loadHistory();
  }

  Future<void> clearDateRange() async {
    state = state.copyWith(clearStartDate: true, clearEndDate: true);
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
        start: state.startDate,
        end: state.endDate,
      );
      state = state.copyWith(tasks: tasks, isLoading: false, clearError: true);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Riwayat tugas gagal dimuat. Coba lagi.',
      );
    }
  }
}
