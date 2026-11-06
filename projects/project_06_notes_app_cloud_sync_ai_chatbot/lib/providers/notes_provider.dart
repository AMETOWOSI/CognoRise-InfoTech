import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/note_reminder_service.dart';
import '../services/notes_service.dart';

enum NotesStatus { loading, loaded, error }

class NotesProvider extends ChangeNotifier {
  NotesProvider(
    this._notesService, {
    String? userId,
    NoteReminderService? reminderService,
  }) : _userId = userId,
       _reminderService = reminderService {
    _listen();
  }

  final NotesService _notesService;
  final String? _userId;
  final NoteReminderService? _reminderService;
  StreamSubscription<List<Note>>? _subscription;
  List<Note> _notes = const [];
  NotesStatus _status = NotesStatus.loading;
  String? _errorMessage;
  bool _isSaving = false;

  List<Note> get notes => List.unmodifiable(_notes);
  NotesStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;

  void _listen() {
    _subscription = _notesService.watchNotes().listen(
      (notes) {
        _notes = notes;
        _status = NotesStatus.loaded;
        _errorMessage = null;
        final userId = _userId;
        final reminderService = _reminderService;
        if (userId != null && reminderService != null) {
          unawaited(_reconcileReminders(userId, reminderService, notes));
        }
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'notes',
            context: ErrorDescription('while listening for Firestore updates'),
          ),
        );
        _status = NotesStatus.error;
        _errorMessage = error is FirebaseException
            ? 'Firestore error (${error.code}): '
                  '${error.message ?? 'No additional details were returned.'}'
            : 'Could not sync your notes. Check your connection.';
        notifyListeners();
      },
    );
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _status = NotesStatus.loading;
    _errorMessage = null;
    notifyListeners();
    _listen();
  }

  Future<String> createNote({
    required String title,
    required String content,
  }) {
    return _runMutation(
      () => _notesService.createNote(title: title, content: content),
    );
  }

  Future<void> updateNote({
    required String id,
    required String title,
    required String content,
  }) {
    return _runMutation(
      () => _notesService.updateNote(id: id, title: title, content: content),
    );
  }

  Future<void> deleteNote(String id) {
    return _runMutation(() => _notesService.deleteNote(id));
  }

  Future<T> _runMutation<T>(Future<T> Function() action) async {
    _isSaving = true;
    notifyListeners();
    try {
      return await action();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _reconcileReminders(
    String userId,
    NoteReminderService reminderService,
    List<Note> notes,
  ) async {
    try {
      await reminderService.reconcileNotes(
        userId,
        notes.map((note) => note.id).toSet(),
      );
    } on Exception catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'notes',
          context: ErrorDescription(
            'while reconciling local note reminders with Firestore',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
