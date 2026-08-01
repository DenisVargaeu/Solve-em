library;

import '../entities/math_note.dart';

/// Persistence contract for math notes (No AI mode).

abstract interface class NotesRepository {
  Future<void> save(MathNote note);
  Future<List<MathNote>> getAll();
  Future<void> delete(String id);
  Future<void> clear();
}
