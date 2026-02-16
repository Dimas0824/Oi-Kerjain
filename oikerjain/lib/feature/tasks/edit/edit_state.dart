import '../../../model/repeat_rule.dart';
import '../../../model/task.dart';
import '../../../model/task_category.dart';
import '../../../model/task_priority.dart';

class EditState {
  const EditState({
    this.editingTask,
    this.title = '',
    this.description = '',
    this.dueDateText = '',
    this.dueTimeText = '',
    this.repeatRule = RepeatRule.none,
    this.category = TaskCategory.work,
    this.priority = TaskPriority.medium,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final Task? editingTask;
  final String title;
  final String description;
  final String dueDateText;
  final String dueTimeText;
  final RepeatRule repeatRule;
  final TaskCategory category;
  final TaskPriority priority;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isEditMode => editingTask != null;

  EditState copyWith({
    Task? editingTask,
    bool preserveEditingTask = true,
    String? title,
    String? description,
    String? dueDateText,
    String? dueTimeText,
    RepeatRule? repeatRule,
    TaskCategory? category,
    TaskPriority? priority,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EditState(
      editingTask: preserveEditingTask
          ? editingTask ?? this.editingTask
          : editingTask,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDateText: dueDateText ?? this.dueDateText,
      dueTimeText: dueTimeText ?? this.dueTimeText,
      repeatRule: repeatRule ?? this.repeatRule,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
