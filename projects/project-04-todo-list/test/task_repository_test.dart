import 'dart:io';

import 'package:test/test.dart';

import 'package:task_manager/exceptions/task_exception.dart';
import 'package:task_manager/models/basic_task.dart';
import 'package:task_manager/models/priority.dart';
import 'package:task_manager/repositories/task_repository.dart';

void main() {
  late Directory tempDirectory;
  late TaskRepository repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('task_manager_test');

    repository = TaskRepository(filePath: '${tempDirectory.path}/tasks.json');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('should add a task', () async {
    final task = BasicTask(1, 'Learn Dart', Priority.high, null, false);

    final result = await repository.add(task);

    expect(result.id, 1);

    final tasks = await repository.getAll();

    expect(tasks.length, 1);
  });

  test('should find a task by ID', () async {
    final task = BasicTask(1, 'Learn Dart', Priority.high, null, false);

    await repository.add(task);

    final result = await repository.getById(1);

    expect(result.title, 'Learn Dart');
  });

  test('should throw when task does not exist', () async {
    expect(
      () => repository.getById(999),
      throwsA(isA<TaskNotFoundException>()),
    );
  });

  test('should delete a task', () async {
    final task = BasicTask(1, 'Learn Dart', Priority.high, null, false);

    await repository.add(task);
    await repository.delete(1);

    final tasks = await repository.getAll();

    expect(tasks, isEmpty);
  });

  test('should persist tasks to JSON', () async {
    final task = BasicTask(1, 'Persistent task', Priority.medium, null, false);

    await repository.add(task);

    final file = File('${tempDirectory.path}/tasks.json');

    expect(await file.exists(), true);
  });
}
