library;

import '../entities/solved_problem.dart';
import '../repositories/problem_repository.dart';

/// Saves a solved problem into history.
class SaveProblemUseCase {
  SaveProblemUseCase(this._repository);
  final ProblemRepository _repository;

  Future<void> call(SolvedProblem problem) => _repository.save(problem);
}

/// Returns all saved problems (newest first).
class GetProblemsUseCase {
  GetProblemsUseCase(this._repository);
  final ProblemRepository _repository;

  Future<List<SolvedProblem>> call() => _repository.getAll();
}

/// Returns a single problem by id.
class GetProblemByIdUseCase {
  GetProblemByIdUseCase(this._repository);
  final ProblemRepository _repository;

  Future<SolvedProblem?> call(String id) => _repository.getById(id);
}

/// Deletes a single problem.
class DeleteProblemUseCase {
  DeleteProblemUseCase(this._repository);
  final ProblemRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}

/// Clears the whole history.
class ClearHistoryUseCase {
  ClearHistoryUseCase(this._repository);
  final ProblemRepository _repository;

  Future<void> call() => _repository.clear();
}
