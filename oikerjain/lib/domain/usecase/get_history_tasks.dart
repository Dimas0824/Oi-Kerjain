import '../../model/task.dart';
import '../task_repository.dart';

class GetHistoryTasksUseCase {
  const GetHistoryTasksUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<Task>> call({DateTime? start, DateTime? end}) {
    return _repository.getHistoryTasks(start: start, end: end);
  }
}
