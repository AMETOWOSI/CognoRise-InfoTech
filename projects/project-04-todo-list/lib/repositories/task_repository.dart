import 'dart:convert';
import 'dart:io';

import 'package:task_manager/models/task.dart';
import 'package:task_manager/models/task_factory.dart';
import 'package:task_manager/repositories/repository.dart';
import 'package:task_manager/exceptions/task_exception.dart';

class TaskRepository implements Repository<Task> {
  final List<Task> tasks = [];

  final String filePath;

  TaskRepository({this.filePath = 'data/tasks.json'});

  @override
  Future<List<Task>> getAll() async {
    await _loadTasks();
    return List.unmodifiable(tasks);
  }

  @override
  Future<Task> getById(int id) async {
    await _loadTasks();

    try {
      return tasks.firstWhere((task) => task.id == id);
    } catch (_) {
      throw TaskNotFoundException(id);
    }
  }

  @override
  Future<Task> add(Task task) async {
    await _loadTasks();

    final existing = tasks.any((existingTask) => existingTask.id == task.id);

    if (existing) {
      throw InvalidTaskException('A task with ID ${task.id} already exists.');
    }

    tasks.add(task);

    await _saveTasks();

    return task;
  }

  @override
  Future<Task> update(Task task) async {
    await _loadTasks();

    final index = tasks.indexWhere(
      (existingTask) => existingTask.id == task.id,
    );

    if (index == -1) {
      throw TaskNotFoundException(task.id);
    }

    tasks[index] = task;

    await _saveTasks();

    return task;
  }

  @override
  Future<void> delete(int id) async {
    await _loadTasks();

    final index = tasks.indexWhere((task) => task.id == id);

    if (index == -1) {
      throw TaskNotFoundException(id);
    }

    tasks.removeAt(index);

    await _saveTasks();
  }

  Future<void> _saveTasks() async {
    final data = tasks.map((task) => task.toJson()).toList();

    final json = const JsonEncoder.withIndent('  ').convert(data);

    final file = File(filePath);

    await file.parent.create(recursive: true);

    await file.writeAsString(json);
  }

  Future<void> _loadTasks() async {
    final file = File(filePath);

    if (!await file.exists()) {
      return;
    }

    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      return;
    }

    final decoded = jsonDecode(content);

    if (decoded is! List) {
      throw const FormatException('Invalid tasks.json format.');
    }

    tasks.clear();

    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        tasks.add(TaskFactory.fromJson(item));
      } else {
        throw const FormatException('Invalid task data.');
      }
    }
  }
}
