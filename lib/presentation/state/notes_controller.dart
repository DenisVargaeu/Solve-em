library;

import 'package:flutter/foundation.dart';

import '../../domain/entities/math_note.dart';
import '../../domain/usecases/note_usecases.dart';

/// Loads and manages the user's offline math notes.

class NotesController extends ChangeNotifier {
  NotesController({
    required GetNotesUseCase getNotes,
    required SaveNoteUseCase saveNote,
    required DeleteNoteUseCase deleteNote,
  }) : _getNotes = getNotes,
       _saveNote = saveNote,
       _deleteNote = deleteNote;

  final GetNotesUseCase _getNotes;
  final SaveNoteUseCase _saveNote;
  final DeleteNoteUseCase _deleteNote;

  List<MathNote> _notes = const [];
  List<MathNote> get notes => _notes;

  Future<void> load() async {
    _notes = await _getNotes();
    notifyListeners();
  }

  Future<void> create({required String title, required String content}) async {
    final now = DateTime.now();
    await _saveNote(
      MathNote(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        content: content,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await load();
  }

  Future<void> update(MathNote note) async {
    await _saveNote(note);
    await load();
  }

  Future<void> remove(String id) async {
    await _deleteNote(id);
    await load();
  }
}
