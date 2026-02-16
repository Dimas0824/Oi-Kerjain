enum TaskCategory { work, personal }

extension TaskCategoryX on TaskCategory {
  static TaskCategory fromName(String raw) {
    switch (raw) {
      case 'work':
      case 'kuliah':
        return TaskCategory.work;
      case 'personal':
      case 'pribadi':
        return TaskCategory.personal;
      default:
        return TaskCategory.work;
    }
  }

  String get label {
    switch (this) {
      case TaskCategory.work:
        return 'Kerja';
      case TaskCategory.personal:
        return 'Pribadi';
    }
  }
}
