library;

import 'package:ai_photomat/domain/entities/solved_problem.dart';
import 'package:ai_photomat/domain/repositories/problem_repository.dart';
import 'package:ai_photomat/data/models/solved_problem_model.dart';
import 'package:ai_photomat/data/datasources/local/problem_local_datasource.dart';

/// Hive-backed implementation of [ProblemRepository].

class ProblemRepositoryImpl implements ProblemRepository {
  ProblemRepositoryImpl(this._local);

  final ProblemLocalDatasource _local;

  @override
  Future<void> save(SolvedProblem problem) =>
      _local.put(problem.id, SolvedProblemModel.toMap(problem));

  @override
  Future<List<SolvedProblem>> getAll() async {
    final maps = await _local.getAll();
    return maps.map(SolvedProblemModel.fromMap).toList();
  }

  @override
  Future<SolvedProblem?> getById(String id) async {
    final map = await _local.get(id);
    return map == null ? null : SolvedProblemModel.fromMap(map);
  }

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<void> clear() => _local.clear();
}
