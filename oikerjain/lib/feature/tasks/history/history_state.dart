import '../../../model/task.dart';

class HistoryState {
  const HistoryState({
    this.tasks = const <Task>[],
    this.startDate,
    this.endDate,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Task> tasks;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isLoading;
  final String? errorMessage;

  bool get hasDateFilter => startDate != null || endDate != null;

  HistoryState copyWith({
    List<Task>? tasks,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      tasks: tasks ?? this.tasks,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
