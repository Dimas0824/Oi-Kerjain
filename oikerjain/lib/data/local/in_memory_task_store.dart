import '../../core/time/clock.dart';
import '../../model/task.dart';
import 'task_store.dart';

class InMemoryTaskStore implements TaskStore {
  InMemoryTaskStore({Clock? clock, List<Task>? seedTasks})
    : _clock = clock ?? const Clock(),
      _tasks = List<Task>.from(
        seedTasks ?? _buildSeedTasks((clock ?? const Clock()).now()),
      );

  final Clock _clock;
  List<Task> _tasks;

  @override
  Future<List<Task>> readAll() async {
    return List<Task>.from(_tasks);
  }

  @override
  Future<void> writeAll(List<Task> tasks) async {
    _tasks = List<Task>.from(tasks);
  }

  static List<Task> _buildSeedTasks(DateTime _) {
    return <Task>[];
  }

  Clock get clock => _clock;
}
