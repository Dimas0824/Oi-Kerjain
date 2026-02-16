import '../task_repository.dart';

class CleanupExpiredHistoryUseCase {
  const CleanupExpiredHistoryUseCase(this._repository);

  final TaskRepository _repository;

  Future<void> call() => _repository.cleanupExpiredHistory();
}
