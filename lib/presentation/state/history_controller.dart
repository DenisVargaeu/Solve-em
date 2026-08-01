library;

import 'package:flutter/foundation.dart';

import '../../domain/entities/solved_problem.dart';
import '../../domain/usecases/problem_usecases.dart';

/// Loads and manages the persisted history of solved problems.

class HistoryController extends ChangeNotifier {
  HistoryController({
    required GetProblemsUseCase getProblems,
    required SaveProblemUseCase saveProblem,
    required DeleteProblemUseCase deleteProblem,
    required ClearHistoryUseCase clearHistory,
  }) : _getProblems = getProblems,
       _saveProblem = saveProblem,
       _deleteProblem = deleteProblem,
       _clearHistory = clearHistory;

  final GetProblemsUseCase _getProblems;
  final SaveProblemUseCase _saveProblem;
  final DeleteProblemUseCase _deleteProblem;
  final ClearHistoryUseCase _clearHistory;

  List<SolvedProblem> _problems = const [];
  List<SolvedProblem> get problems => _problems;

  bool _loading = false;
  bool get loading => _loading;

  /// Loads all problems (newest first) into memory.
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final all = await _getProblems();
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _problems = all;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Persists a problem and refreshes the list.
  Future<void> add(SolvedProblem problem) async {
    await _saveProblem(problem);
    await load();
  }

  Future<void> remove(String id) async {
    await _deleteProblem(id);
    await load();
  }

  /// Clears the whole history with an optional confirmation at the UI layer.
  Future<void> clear() async {
    await _clearHistory();
    await load();
  }
}
