import '../../model/task.dart';
import '../task_repository.dart';

class GetTasksUseCase {
  const GetTasksUseCase(this._repository);

  final TaskRepository _repository;

  Future<List<Task>> call() => _repository.getTasks();
}
