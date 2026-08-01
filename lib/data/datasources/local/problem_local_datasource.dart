library;

import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// Thin wrapper around the Hive box that stores solved problems.
///
/// Values are stored as plain maps (see [SolvedProblemModel]) so no custom
/// Hive adapters or code generation are required.

class ProblemLocalDatasource {
  ProblemLocalDatasource(this._box);

  final Box _box;

  /// Stores/updates one problem.
  Future<void> put(String id, Map<String, dynamic> value) async {
    await _box.put(id, value);
  }

  /// Returns every problem as an unsorted list of maps.
  Future<List<Map<dynamic, dynamic>>> getAll() async {
    return _box.values.whereType<Map>().toList();
  }

  Future<Map<dynamic, dynamic>?> get(String id) async {
    final value = _box.get(id);
    return value is Map ? value : null;
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  /// Convenience for tests / pre-loading.
  static Future<Box> openBox() async {
    await Hive.initFlutter();
    return Hive.openBox<dynamic>(AppConstants.problemsBoxName);
  }
}
