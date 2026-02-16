import '../../../model/task.dart';

enum HistoryFilterMode { weekly, custom }

class HistoryState {
  const HistoryState({
    this.tasks = const <Task>[],
    required this.filterMode,
    required this.weekStartDate,
    this.customStartDate,
    this.customEndDate,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Task> tasks;
  final HistoryFilterMode filterMode;
  final DateTime weekStartDate;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool isLoading;
  final String? errorMessage;

  DateTime get weekEndDate => weekStartDate.add(const Duration(days: 6));

  bool get isCustomActive =>
      filterMode == HistoryFilterMode.custom &&
      customStartDate != null &&
      customEndDate != null;

  DateTime get effectiveStartDate => isCustomActive ? customStartDate! : weekStartDate;

  DateTime get effectiveEndDate => isCustomActive ? customEndDate! : weekEndDate;

  HistoryState copyWith({
    List<Task>? tasks,
    HistoryFilterMode? filterMode,
    DateTime? weekStartDate,
    DateTime? customStartDate,
    bool clearCustomStartDate = false,
    DateTime? customEndDate,
    bool clearCustomEndDate = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      tasks: tasks ?? this.tasks,
      filterMode: filterMode ?? this.filterMode,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      customStartDate: clearCustomStartDate
          ? null
          : customStartDate ?? this.customStartDate,
      customEndDate: clearCustomEndDate
          ? null
          : customEndDate ?? this.customEndDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
