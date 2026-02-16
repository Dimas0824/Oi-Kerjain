import 'repeat_rule.dart';
import 'task_category.dart';
import 'task_priority.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueAtEpochMillis,
    required this.repeatRule,
    required this.priority,
    required this.category,
    required this.isDone,
    required this.updatedAtEpochMillis,
  });

  final String id;
  final String title;
  final String description;
  final int dueAtEpochMillis;
  final RepeatRule repeatRule;
  final TaskPriority priority;
  final TaskCategory category;
  final bool isDone;
  final int updatedAtEpochMillis;

  DateTime get dueAt => DateTime.fromMillisecondsSinceEpoch(dueAtEpochMillis);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'dueAtEpochMillis': dueAtEpochMillis,
      'repeatRule': repeatRule.name,
      'priority': priority.name,
      'category': category.name,
      'isDone': isDone,
      'updatedAtEpochMillis': updatedAtEpochMillis,
    };
  }

  static Task fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    final title = json['title']?.toString();
    final dueAtEpochMillis = (json['dueAtEpochMillis'] as num?)?.toInt();
    final updatedAtEpochMillis = (json['updatedAtEpochMillis'] as num?)?.toInt();

    if (id == null ||
        title == null ||
        dueAtEpochMillis == null ||
        updatedAtEpochMillis == null) {
      throw const FormatException('Invalid task json payload');
    }

    return Task(
      id: id,
      title: title,
      description: json['description']?.toString() ?? '',
      dueAtEpochMillis: dueAtEpochMillis,
      repeatRule: RepeatRuleX.fromName(json['repeatRule']?.toString() ?? ''),
      priority: TaskPriorityX.fromName(json['priority']?.toString() ?? ''),
      category: TaskCategoryX.fromName(json['category']?.toString() ?? ''),
      isDone: json['isDone'] == true,
      updatedAtEpochMillis: updatedAtEpochMillis,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? dueAtEpochMillis,
    RepeatRule? repeatRule,
    TaskPriority? priority,
    TaskCategory? category,
    bool? isDone,
    int? updatedAtEpochMillis,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueAtEpochMillis: dueAtEpochMillis ?? this.dueAtEpochMillis,
      repeatRule: repeatRule ?? this.repeatRule,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      updatedAtEpochMillis: updatedAtEpochMillis ?? this.updatedAtEpochMillis,
    );
  }
}
