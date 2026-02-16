import 'repeat_rule.dart';
import 'task_category.dart';
import 'task_priority.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAtEpochMillis,
    required this.dueAtEpochMillis,
    required this.repeatRule,
    required this.priority,
    required this.category,
    required this.isDone,
    this.completedAtEpochMillis,
    required this.updatedAtEpochMillis,
  });

  final String id;
  final String title;
  final String description;
  final int createdAtEpochMillis;
  final int dueAtEpochMillis;
  final RepeatRule repeatRule;
  final TaskPriority priority;
  final TaskCategory category;
  final bool isDone;
  final int? completedAtEpochMillis;
  final int updatedAtEpochMillis;

  DateTime get createdAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAtEpochMillis);

  DateTime get dueAt => DateTime.fromMillisecondsSinceEpoch(dueAtEpochMillis);

  DateTime? get completedAt => completedAtEpochMillis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(completedAtEpochMillis!);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'createdAtEpochMillis': createdAtEpochMillis,
      'dueAtEpochMillis': dueAtEpochMillis,
      'repeatRule': repeatRule.name,
      'priority': priority.name,
      'category': category.name,
      'isDone': isDone,
      'completedAtEpochMillis': completedAtEpochMillis,
      'updatedAtEpochMillis': updatedAtEpochMillis,
    };
  }

  static Task fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final title = json['title']?.toString();
    final isDone = json['isDone'] == true;
    final dueAtEpochMillis = (json['dueAtEpochMillis'] as num?)?.toInt();
    final updatedAtEpochMillis = (json['updatedAtEpochMillis'] as num?)?.toInt();
    final createdAtEpochMillis =
        (json['createdAtEpochMillis'] as num?)?.toInt() ??
        updatedAtEpochMillis;
    final completedAtEpochMillis =
        (json['completedAtEpochMillis'] as num?)?.toInt() ??
        (isDone ? updatedAtEpochMillis : null);

    if (id == null ||
        title == null ||
        createdAtEpochMillis == null ||
        dueAtEpochMillis == null ||
        updatedAtEpochMillis == null) {
      throw const FormatException('Invalid task json payload');
    }

    return Task(
      id: id,
      title: title,
      description: json['description']?.toString() ?? '',
      createdAtEpochMillis: createdAtEpochMillis,
      dueAtEpochMillis: dueAtEpochMillis,
      repeatRule: RepeatRuleX.fromName(json['repeatRule']?.toString() ?? ''),
      priority: TaskPriorityX.fromName(json['priority']?.toString() ?? ''),
      category: TaskCategoryX.fromName(json['category']?.toString() ?? ''),
      isDone: isDone,
      completedAtEpochMillis: completedAtEpochMillis,
      updatedAtEpochMillis: updatedAtEpochMillis,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? createdAtEpochMillis,
    int? dueAtEpochMillis,
    RepeatRule? repeatRule,
    TaskPriority? priority,
    TaskCategory? category,
    bool? isDone,
    int? completedAtEpochMillis,
    bool clearCompletedAtEpochMillis = false,
    int? updatedAtEpochMillis,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAtEpochMillis: createdAtEpochMillis ?? this.createdAtEpochMillis,
      dueAtEpochMillis: dueAtEpochMillis ?? this.dueAtEpochMillis,
      repeatRule: repeatRule ?? this.repeatRule,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      completedAtEpochMillis: clearCompletedAtEpochMillis
          ? null
          : completedAtEpochMillis ?? this.completedAtEpochMillis,
      updatedAtEpochMillis: updatedAtEpochMillis ?? this.updatedAtEpochMillis,
    );
  }
}
