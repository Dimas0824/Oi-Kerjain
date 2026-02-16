enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  static TaskPriority fromName(String raw) {
    switch (raw) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
      case 'med':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }

  int get rank {
    switch (this) {
      case TaskPriority.low:
        return 1;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.high:
        return 3;
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Rendah';
      case TaskPriority.medium:
        return 'Sedang';
      case TaskPriority.high:
        return 'Tinggi';
    }
  }
}
