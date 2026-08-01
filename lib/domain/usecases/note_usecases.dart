library;

import '../entities/math_note.dart';
import '../repositories/notes_repository.dart';

/// Saves (creates or updates) a note.
class SaveNoteUseCase {
  SaveNoteUseCase(this._repository);
  final NotesRepository _repository;

  Future<void> call(MathNote note) => _repository.save(note);
}

/// Returns all notes (newest first).
class GetNotesUseCase {
  GetNotesUseCase(this._repository);
  final NotesRepository _repository;

  Future<List<MathNote>> call() => _repository.getAll();
}

/// Deletes a note.
class DeleteNoteUseCase {
  DeleteNoteUseCase(this._repository);
  final NotesRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
