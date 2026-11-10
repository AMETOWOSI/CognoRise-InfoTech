import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../services/note_reminder_service.dart';
import '../providers/notes_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/primary_action_button.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({
    super.key,
    required this.userName,
    required this.userEmail,
    this.userPhotoPath,
    required this.userId,
    required this.reminderService,
    required this.onAccountTap,
    required this.onNotificationsTap,
  });

  final String? userName;
  final String? userEmail;
  final String? userPhotoPath;
  final String userId;
  final NoteReminderService reminderService;
  final VoidCallback onAccountTap;
  final VoidCallback onNotificationsTap;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditor({Note? note}) async {
    final notesProvider = context.read<NotesProvider>();
    DateTime? initialReminderAt;
    if (note != null) {
      try {
        initialReminderAt = await widget.reminderService.loadReminderAt(
          widget.userId,
          note.id,
        );
      } on Exception catch (error, stackTrace) {
        _reportReminderError(error, stackTrace, 'loading a note reminder');
        if (mounted) _showMessage('Could not load this note reminder.');
        return;
      }
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<NotesProvider>.value(
        value: notesProvider,
        child: _NoteEditorSheet(
          note: note,
          userId: widget.userId,
          reminderService: widget.reminderService,
          initialReminderAt: initialReminderAt,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Note note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('“${note.title}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    try {
      await context.read<NotesProvider>().deleteNote(note.id);
      try {
        await widget.reminderService.scheduleReminder(
          userId: widget.userId,
          noteId: note.id,
          reminderAt: null,
        );
      } on Exception catch (error, stackTrace) {
        _reportReminderError(
          error,
          stackTrace,
          'canceling a deleted note reminder',
        );
        if (mounted) {
          _showMessage(
            'The note was deleted, but its reminder could not be canceled.',
          );
        }
        return;
      }
      if (mounted) _showMessage('Note deleted.');
    } on FirebaseException catch (error, stackTrace) {
      _reportFirestoreError(error, stackTrace, 'deleting a note');
      if (mounted) {
        _showMessage(
          'Could not delete the note (${error.code}). '
          '${error.message ?? 'Try again.'}',
        );
      }
    } on Exception catch (error, stackTrace) {
      _reportFirestoreError(error, stackTrace, 'deleting a note');
      if (mounted) _showMessage('An unexpected error occurred.');
    }
  }

  void _reportFirestoreError(
    Object error,
    StackTrace stackTrace,
    String action,
  ) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'notes',
        context: ErrorDescription('while $action'),
      ),
    );
  }

  void _reportReminderError(
    Object error,
    StackTrace stackTrace,
    String action,
  ) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'note reminders',
        context: ErrorDescription('while $action'),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('createNoteButton'),
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NotesHeader(
                  userName: widget.userName,
                  userEmail: widget.userEmail,
                  userPhotoPath: widget.userPhotoPath,
                  onAccountTap: widget.onAccountTap,
                  onNotificationsTap: widget.onNotificationsTap,
                ),
                const SizedBox(height: 22),
                TextField(
                  key: const Key('noteSearchField'),
                  controller: _searchController,
                  onChanged: (value) => setState(() {
                    _searchTerm = value.trim().toLowerCase();
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search your notes',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchTerm.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchTerm = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text(
                      'Your notes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Consumer<NotesProvider>(
                      builder: (context, provider, _) => Text(
                        '${provider.notes.length} ${provider.notes.length == 1 ? 'note' : 'notes'}',
                        style: const TextStyle(
                          color: AppColors.mutedInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Consumer<NotesProvider>(
                    builder: (context, provider, _) {
                      return switch (provider.status) {
                        NotesStatus.loading => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        NotesStatus.error => _NotesError(
                          message:
                              provider.errorMessage ?? 'Could not load notes.',
                          onRetry: provider.retry,
                        ),
                        NotesStatus.loaded => _buildNotes(provider),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotes(NotesProvider provider) {
    final notes = provider.notes.where((note) {
      return note.title.toLowerCase().contains(_searchTerm) ||
          note.content.toLowerCase().contains(_searchTerm);
    }).toList();

    if (notes.isEmpty) {
      return _EmptyNotes(
        isSearching: _searchTerm.isNotEmpty,
        onCreate: () => _openEditor(),
      );
    }

    return ListView.separated(
      key: const Key('notesList'),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: notes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final note = notes[index];
        return _NoteCard(
          note: note,
          onTap: () => _openEditor(note: note),
          onDelete: () => _confirmDelete(note),
        );
      },
    );
  }
}

class _NotesHeader extends StatelessWidget {
  const _NotesHeader({
    required this.userName,
    required this.userEmail,
    this.userPhotoPath,
    required this.onAccountTap,
    required this.onNotificationsTap,
  });

  final String? userName;
  final String? userEmail;
  final String? userPhotoPath;
  final VoidCallback onAccountTap;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final firstPart = userName?.trim().isNotEmpty == true
        ? userName!.trim()
        : userEmail?.split('@').first ?? 'there';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                key: const Key('accountInfoButton'),
                tooltip: 'Account information',
                onPressed: onAccountTap,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.blue.withValues(alpha: 0.12),
                  fixedSize: const Size(48, 48),
                ),
                icon: CircleAvatar(
                  key: const Key('homeProfilePhoto'),
                  radius: 24,
                  backgroundColor: AppColors.blue.withValues(alpha: 0.12),
                  child: userPhotoPath == null || userPhotoPath!.isEmpty
                      ? const Icon(
                          Icons.account_circle_outlined,
                          color: AppColors.blue,
                          size: 31,
                        )
                      : ClipOval(
                          child: Image.file(
                            key: const Key('homeProfilePhotoImage'),
                            File(userPhotoPath!),
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.account_circle_outlined,
                              color: AppColors.blue,
                              size: 31,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back,',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedInk),
              ),
              Text(
                firstPart,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('notificationsButton'),
          tooltip: 'Notifications',
          onPressed: onNotificationsTap,
          icon: const Icon(Icons.notifications_none_outlined),
          color: AppColors.blue,
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 8, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 42,
                  width: 42,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.sticky_note_2_outlined,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        note.content.isEmpty
                            ? 'No additional text'
                            : note.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.mutedInk,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(note.updatedAt),
                        style: const TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Note actions',
                  onSelected: (_) => onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'Just now';
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$month/$day/${local.year}';
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.isSearching, required this.onCreate});

  final bool isSearching;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.note_add_outlined,
              size: 46,
              color: AppColors.blue,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching ? 'No matching notes' : 'Your notes start here',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try another search.'
                  : 'Capture an idea before it slips away.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedInk),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 18),
              PrimaryActionButton(
                label: 'Create a note',
                icon: Icons.add,
                onPressed: onCreate,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotesError extends StatelessWidget {
  const _NotesError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 42, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet({
    this.note,
    required this.userId,
    required this.reminderService,
    required this.initialReminderAt,
  });

  final Note? note;
  final String userId;
  final NoteReminderService reminderService;
  final DateTime? initialReminderAt;

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _saveErrorMessage;
  String? _reminderErrorMessage;
  String? _savedNoteId;
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _reminderAt = widget.initialReminderAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });
    var noteSaved = false;
    try {
      final provider = context.read<NotesProvider>();
      final existingId = _savedNoteId ?? widget.note?.id;
      final noteId =
          existingId ??
          await provider.createNote(
            title: _titleController.text,
            content: _contentController.text,
          );
      _savedNoteId = noteId;
      if (existingId != null) {
        await provider.updateNote(
          id: noteId,
          title: _titleController.text,
          content: _contentController.text,
        );
      }
      noteSaved = true;
      await widget.reminderService.scheduleReminder(
        userId: widget.userId,
        noteId: noteId,
        reminderAt: _reminderAt,
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error, stackTrace) {
      _reportSaveError(error, stackTrace);
      if (mounted) {
        setState(() => _saveErrorMessage = _firestoreErrorMessage(error));
      }
    } on Exception catch (error, stackTrace) {
      _reportSaveError(error, stackTrace);
      if (mounted) {
        setState(
          () => _saveErrorMessage = noteSaved
              ? 'Your note was saved, but its reminder could not be updated. '
                    'Please check notification permission and try again.'
              : 'Unexpected error: $error. Your note was not saved.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10, now.month, now.day),
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _reminderAt == null
          ? TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30)))
          : TimeOfDay.fromDateTime(_reminderAt!),
    );
    if (selectedTime == null || !mounted) return;

    final reminderAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    if (!reminderAt.isAfter(DateTime.now())) {
      setState(() {
        _reminderErrorMessage = 'Choose a time in the future.';
      });
      return;
    }

    try {
      final permissionGranted = await widget.reminderService
          .requestPermission();
      if (!mounted) return;
      if (!permissionGranted) {
        setState(() {
          _reminderErrorMessage =
              'Allow notifications in Android settings to use reminders.';
        });
        return;
      }
      setState(() {
        _reminderAt = reminderAt;
        _reminderErrorMessage = null;
        _saveErrorMessage = null;
      });
    } on Exception catch (error, stackTrace) {
      _reportReminderError(
        error,
        stackTrace,
        'requesting notification permission',
      );
      if (mounted) {
        setState(() {
          _reminderErrorMessage =
              'Could not enable notifications. Check Android settings and try '
              'again.';
        });
      }
    }
  }

  void _reportSaveError(Object error, StackTrace stackTrace) {
    debugPrint('Error while saving a note: $error\n$stackTrace');
  }

  void _reportReminderError(
    Object error,
    StackTrace stackTrace,
    String action,
  ) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'note reminders',
        context: ErrorDescription('while $action'),
      ),
    );
  }

  String _firestoreErrorMessage(FirebaseException error) {
    final explanation = switch (error.code) {
      'permission-denied' =>
        'Firestore denied this write. Confirm you are signed in and the '
            'deployed rules allow this user to write notes.',
      'unauthenticated' =>
        'Your sign-in session has expired. Sign in again and retry.',
      'unavailable' || 'deadline-exceeded' =>
        'Firebase is unreachable. Check the phone’s internet connection.',
      'failed-precondition' =>
        'Firestore is not ready for this operation. Check the Firebase '
            'project configuration.',
      _ => error.message ?? 'Check Firebase configuration and try again.',
    };
    return 'Could not save your note (${error.code}). $explanation';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedInk.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.note == null ? 'New note' : 'Edit note',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  key: const Key('noteTitleField'),
                  controller: _titleController,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'A short, clear title',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'A title is required.';
                    }
                    return null;
                  },
                ),
                if (_saveErrorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('noteSaveError'),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _saveErrorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('noteContentField'),
                  controller: _contentController,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 20000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Your note',
                    hintText: 'Write down what you want to remember…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                AppPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _reminderAt == null
                                  ? 'No reminder'
                                  : 'Reminder set',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (_reminderAt != null)
                              Text(
                                '${MaterialLocalizations.of(context).formatFullDate(_reminderAt!)} · '
                                '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_reminderAt!))}',
                                style: const TextStyle(
                                  color: AppColors.mutedInk,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_reminderAt != null)
                        IconButton(
                          key: const Key('clearNoteReminderButton'),
                          tooltip: 'Clear reminder',
                          onPressed: () => setState(() {
                            _reminderAt = null;
                            _reminderErrorMessage = null;
                          }),
                          icon: const Icon(Icons.close),
                        ),
                      TextButton(
                        key: const Key('setNoteReminderButton'),
                        onPressed: _isSaving ? null : _pickReminder,
                        child: Text(_reminderAt == null ? 'Set' : 'Change'),
                      ),
                    ],
                  ),
                ),
                if (_reminderErrorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _reminderErrorMessage!,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                PrimaryActionButton(
                  label: widget.note == null ? 'Save note' : 'Save changes',
                  icon: Icons.check,
                  onPressed: _save,
                  isLoading: _isSaving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
