import '../../../model/task.dart';
import '../../../model/task_category.dart';
import '../../../model/task_priority.dart';

enum TaskCategoryFilter { all, work, personal }

extension TaskCategoryFilterX on TaskCategoryFilter {
  String get label {
    switch (this) {
      case TaskCategoryFilter.all:
        return 'Semua';
      case TaskCategoryFilter.work:
        return 'Kerja';
      case TaskCategoryFilter.personal:
        return 'Pribadi';
    }
  }

  TaskCategory? get category {
    switch (this) {
      case TaskCategoryFilter.all:
        return null;
      case TaskCategoryFilter.work:
        return TaskCategory.work;
      case TaskCategoryFilter.personal:
        return TaskCategory.personal;
    }
  }
}

class HomeState {
  const HomeState({
    this.tasks = const <Task>[],
    this.filterCategory = TaskCategoryFilter.all,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Task> tasks;
  final TaskCategoryFilter filterCategory;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  int get totalTasks => tasks.length;

  int get completedTasks => tasks.where((task) => task.isDone).length;

  int get pendingTasks => tasks.where((task) => !task.isDone).length;

  int get progress {
    if (tasks.isEmpty) {
      return 0;
    }
    return ((completedTasks / tasks.length) * 100).round();
  }

  List<Task> visibleTasks() {
    final selectedCategory = filterCategory.category;
    final query = searchQuery.trim().toLowerCase();

    return tasks.where((task) {
      final categoryMatch =
          selectedCategory == null || task.category == selectedCategory;
      final textMatch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);
      return categoryMatch && textMatch;
    }).toList();
  }

  Task? criticalTask() {
    final active = tasks.where((task) => !task.isDone).toList();
    if (active.isEmpty) {
      return null;
    }

    active.sort((a, b) {
      final priorityCompare = b.priority.rank.compareTo(a.priority.rank);
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      final dueCompare = a.dueAtEpochMillis.compareTo(b.dueAtEpochMillis);
      if (dueCompare != 0) {
        return dueCompare;
      }

      return b.updatedAtEpochMillis.compareTo(a.updatedAtEpochMillis);
    });
    return active.first;
  }

  HomeState copyWith({
    List<Task>? tasks,
    TaskCategoryFilter? filterCategory,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      tasks: tasks ?? this.tasks,
      filterCategory: filterCategory ?? this.filterCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
