library;

import '../entities/solved_problem.dart';

/// Persistence contract for solved problems.

abstract interface class ProblemRepository {
  /// Saves (inserts or replaces) a solved problem.
  Future<void> save(SolvedProblem problem);

  /// Returns all saved problems, newest first.
  Future<List<SolvedProblem>> getAll();

  /// Returns a single problem by [id].
  Future<SolvedProblem?> getById(String id);

  /// Deletes one problem.
  Future<void> delete(String id);

  /// Clears the entire history.
  Future<void> clear();
}
