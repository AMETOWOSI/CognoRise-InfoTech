import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager/exceptions/task_exception.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/models/task_factory.dart';
import 'package:task_manager/repositories/repository.dart';

class SharedPreferencesTaskRepository implements Repository<Task> {
  static const _storageKey = 'tasks';

  final SharedPreferences _preferences;

  SharedPreferencesTaskRepository(this._preferences);

  static Future<SharedPreferencesTaskRepository> create() async {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesTaskRepository(preferences);
  }

  @override
  Future<List<Task>> getAll() async => List.unmodifiable(await _readTasks());

  @override
  Future<Task> getById(int id) async {
    final tasks = await _readTasks();
    return tasks.firstWhere(
      (task) => task.id == id,
      orElse: () => throw TaskNotFoundException(id),
    );
  }

  @override
  Future<Task> add(Task task) async {
    final tasks = await _readTasks();
    if (tasks.any((existing) => existing.id == task.id)) {
      throw InvalidTaskException('A task with ID ${task.id} already exists.');
    }
    tasks.add(task);
    await _saveTasks(tasks);
    return task;
  }

  @override
  Future<Task> update(Task task) async {
    final tasks = await _readTasks();
    final index = tasks.indexWhere((existing) => existing.id == task.id);
    if (index == -1) {
      throw TaskNotFoundException(task.id);
    }
    tasks[index] = task;
    await _saveTasks(tasks);
    return task;
  }

  @override
  Future<void> delete(int id) async {
    final tasks = await _readTasks();
    final index = tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      throw TaskNotFoundException(id);
    }
    tasks.removeAt(index);
    await _saveTasks(tasks);
  }

  Future<List<Task>> _readTasks() async {
    final encoded = _preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('Invalid stored task list.');
    }

    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid stored task.');
      }
      return TaskFactory.fromJson(item);
    }).toList();
  }

  Future<void> _saveTasks(List<Task> tasks) async {
    final encoded = jsonEncode(tasks.map((task) => task.toJson()).toList());
    final saved = await _preferences.setString(_storageKey, encoded);
    if (!saved) {
      throw StateError('Could not save tasks to local storage.');
    }
  }
}
