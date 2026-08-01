library;

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/math_note.dart';
import '../../domain/repositories/notes_repository.dart';

/// Hive-backed implementation of [NotesRepository].

class NotesRepositoryImpl implements NotesRepository {
  NotesRepositoryImpl(this._box);

  final Box _box;

  @override
  Future<void> save(MathNote note) async {
    await _box.put(note.id, note.toMap());
  }

  @override
  Future<List<MathNote>> getAll() async {
    return _box.values.whereType<Map>().map(MathNote.fromMap).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> clear() async {
    await _box.clear();
  }

  static Future<Box> openBox() async {
    await Hive.initFlutter();
    return Hive.openBox<dynamic>(AppConstants.notesBoxName);
  }
}
