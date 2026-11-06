import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract interface class NoteReminderService {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<DateTime?> loadReminderAt(String userId, String noteId);

  Future<void> scheduleReminder({
    required String userId,
    required String noteId,
    required DateTime? reminderAt,
  });

  Future<void> reconcileNotes(String userId, Set<String> noteIds);
}

class LocalNoteReminderService implements NoteReminderService {
  LocalNoteReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static final instance = LocalNoteReminderService();

  static const _nextIdKey = 'noteflow_next_note_reminder_id';
  static const _channelId = 'note_reminders';
  static const _channelName = 'Note reminders';
  static const _channelDescription = 'Reminders you set for your notes.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    final initialized = await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    if (initialized == false) {
      throw const NoteReminderException(
        'The local notification plugin could not initialize.',
      );
    }
    _isInitialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isInitialized) await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<DateTime?> loadReminderAt(String userId, String noteId) async {
    final preferences = await SharedPreferences.getInstance();
    final record = _readRecord(preferences, _storageKey(userId, noteId));
    if (record == null) return null;

    final reminderAt = DateTime.fromMillisecondsSinceEpoch(
      record.timestamp,
      isUtc: true,
    ).toLocal();
    if (!reminderAt.isAfter(DateTime.now())) {
      if (!_isInitialized) await initialize();
      await _plugin.cancel(record.notificationId);
      await preferences.remove(_storageKey(userId, noteId));
      return null;
    }
    return reminderAt;
  }

  @override
  Future<void> scheduleReminder({
    required String userId,
    required String noteId,
    required DateTime? reminderAt,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key = _storageKey(userId, noteId);
    final current = _readRecord(preferences, key);

    if (reminderAt == null) {
      if (current != null) {
        if (!_isInitialized) await initialize();
        await _plugin.cancel(current.notificationId);
      }
      await preferences.remove(key);
      return;
    }
    if (!reminderAt.isAfter(DateTime.now())) {
      throw const NoteReminderException(
        'Choose a reminder time in the future.',
      );
    }
    if (!_isInitialized) await initialize();
    if (!await requestPermission()) {
      throw const NotificationPermissionDeniedException();
    }

    final notificationId =
        current?.notificationId ?? await _allocateId(preferences);
    final timestamp = reminderAt.toUtc().millisecondsSinceEpoch;
    final stored = await preferences.setString(
      key,
      jsonEncode({'id': notificationId, 'timestamp': timestamp}),
    );
    if (!stored) {
      throw const NoteReminderException(
        'The local reminder could not be saved on this device.',
      );
    }

    try {
      await _plugin.zonedSchedule(
        notificationId,
        'Note reminder',
        'Open NoteFlow to review your note.',
        tz.TZDateTime.from(reminderAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on Exception {
      await _plugin.cancel(notificationId);
      await preferences.remove(key);
      rethrow;
    }
  }

  @override
  Future<void> reconcileNotes(String userId, Set<String> noteIds) async {
    final preferences = await SharedPreferences.getInstance();
    final prefix = _userPrefix(userId);
    final orphanedKeys = preferences.getKeys().where((key) {
      return key.startsWith(prefix) &&
          !noteIds.contains(Uri.decodeComponent(key.substring(prefix.length)));
    }).toList();
    if (orphanedKeys.isEmpty) return;
    if (!_isInitialized) await initialize();

    for (final key in orphanedKeys) {
      final record = _readRecord(preferences, key);
      if (record != null) await _plugin.cancel(record.notificationId);
      await preferences.remove(key);
    }
  }

  Future<int> _allocateId(SharedPreferences preferences) async {
    final current = preferences.getInt(_nextIdKey) ?? 1;
    if (current < 1 || current >= 0x7fffffff) {
      throw const NoteReminderException(
        'The local notification ID range has been exhausted.',
      );
    }
    if (!await preferences.setInt(_nextIdKey, current + 1)) {
      throw const NoteReminderException(
        'A local notification ID could not be saved.',
      );
    }
    return current;
  }

  _StoredReminder? _readRecord(SharedPreferences preferences, String key) {
    final encoded = preferences.getString(key);
    if (encoded == null) return null;

    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic> ||
        decoded['id'] is! int ||
        decoded['timestamp'] is! int) {
      throw const FormatException('A saved note reminder is invalid.');
    }
    return _StoredReminder(
      notificationId: decoded['id'] as int,
      timestamp: decoded['timestamp'] as int,
    );
  }

  String _storageKey(String userId, String noteId) =>
      '${_userPrefix(userId)}${Uri.encodeComponent(noteId)}';

  String _userPrefix(String userId) =>
      'noteflow_note_reminder_${Uri.encodeComponent(userId)}_';

}

class _StoredReminder {
  const _StoredReminder({
    required this.notificationId,
    required this.timestamp,
  });

  final int notificationId;
  final int timestamp;
}

class NotificationPermissionDeniedException implements Exception {
  const NotificationPermissionDeniedException();
}

class NoteReminderException implements Exception {
  const NoteReminderException(this.message);

  final String message;

  @override
  String toString() => message;
}
