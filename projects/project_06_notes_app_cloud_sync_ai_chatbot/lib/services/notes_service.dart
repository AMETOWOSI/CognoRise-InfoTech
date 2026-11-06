import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note.dart';

abstract interface class NotesService {
  Stream<List<Note>> watchNotes();

  Future<String> createNote({required String title, required String content});

  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
  });

  Future<void> deleteNote(String id);
}

class FirestoreNotesService implements NotesService {
  FirestoreNotesService({
    required String userId,
    FirebaseFirestore? firestore,
  }) : _notes = (firestore ?? FirebaseFirestore.instance)
           .collection('users')
           .doc(userId)
           .collection('notes');

  final CollectionReference<Map<String, dynamic>> _notes;

  @override
  Stream<List<Note>> watchNotes() {
    return _notes
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Note.fromDocument).toList());
  }

  @override
  Future<String> createNote({
    required String title,
    required String content,
  }) async {
    final document = _notes.doc();
    final now = FieldValue.serverTimestamp();
    await document.set({
      'title': title.trim(),
      'content': content.trim(),
      'createdAt': now,
      'updatedAt': now,
    });
    return document.id;
  }

  @override
  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
  }) async {
    await _notes.doc(id).update({
      'title': title.trim(),
      'content': content.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteNote(String id) => _notes.doc(id).delete();
}
