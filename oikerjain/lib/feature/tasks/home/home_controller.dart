import 'package:flutter_riverpod/legacy.dart' as legacy;

import '../../../core/time/clock.dart';
import '../../../domain/usecase/delete_task.dart';
import '../../../domain/usecase/get_tasks.dart';
import '../../../domain/usecase/mark_done.dart';
import '../../../model/task.dart';
import 'home_state.dart';

class HomeController extends legacy.StateNotifier<HomeState> {
  HomeController({
    required GetTasksUseCase getTasks,
    required MarkDoneUseCase markDone,
    required DeleteTaskUseCase deleteTask,
    required Clock clock,
  }) : _getTasks = getTasks,
       _markDone = markDone,
       _deleteTask = deleteTask,
       _clock = clock,
       super(const HomeState(isLoading: true)) {
    _loadTasks();
  }

  final GetTasksUseCase _getTasks;
  final MarkDoneUseCase _markDone;
  final DeleteTaskUseCase _deleteTask;
  final Clock _clock;

  Future<void> refresh() => _loadTasks();

  void setCategoryFilter(TaskCategoryFilter filter) {
    if (state.filterCategory == filter) {
      return;
    }
    state = state.copyWith(filterCategory: filter, clearError: true);
  }

  void setSearchQuery(String value) {
    if (state.searchQuery == value) {
      return;
    }
    state = state.copyWith(searchQuery: value, clearError: true);
  }

  Future<void> toggleStatus(String taskId) async {
    final target = _findTaskById(taskId);
    if (target == null) {
      return;
    }

    try {
      await _markDone(target, isDone: !target.isDone);
      await _loadTasks();
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Status tugas gagal diperbarui. Coba lagi.',
      );
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _deleteTask(taskId);
      await _loadTasks();
    } catch (_) {
      state = state.copyWith(errorMessage: 'Tugas gagal dihapus. Coba lagi.');
    }
  }

  bool isOverdue(Task task) {
    return !task.isDone &&
        task.dueAtEpochMillis < _clock.now().millisecondsSinceEpoch;
  }

  Task? _findTaskById(String taskId) {
    for (final task in state.tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  Future<void> _loadTasks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tasks = await _getTasks();
      state = state.copyWith(tasks: tasks, isLoading: false, clearError: true);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Daftar tugas gagal dimuat. Coba lagi.',
      );
    }
  }
}
