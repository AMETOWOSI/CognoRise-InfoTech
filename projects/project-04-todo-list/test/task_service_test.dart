import 'dart:io';

import 'package:test/test.dart';

import 'package:task_manager/exceptions/task_exception.dart';
import 'package:task_manager/models/priority.dart';
import 'package:task_manager/models/urgent_task.dart';
import 'package:task_manager/repositories/task_repository.dart';
import 'package:task_manager/services/task_service.dart';

void main() {
  late Directory tempDirectory;
  late TaskService service;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('task_service_test');

    final repository = TaskRepository(
      filePath: '${tempDirectory.path}/tasks.json',
    );

    service = TaskService(repository);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('should create a task with generated ID', () async {
    final task = await service.addTask(
      title: 'Study Dart',
      priority: Priority.high,
    );

    expect(task.id, 1);
    expect(task.title, 'Study Dart');
  });

  test('should reject an empty title', () async {
    expect(
      () => service.addTask(title: '', priority: Priority.low),
      throwsA(isA<InvalidTaskException>()),
    );
  });

  test('should mark a task as completed', () async {
    final task = await service.addTask(
      title: 'Finish project',
      priority: Priority.high,
    );

    final completed = await service.completeTask(task.id);

    expect(completed.completed, true);
  });

  test('should create an urgent task', () async {
    final task = await service.addTask(
      title: 'Critical bug',
      priority: Priority.high,
      urgent: true,
      urgencyLevel: 5,
    );

    expect(task, isA<UrgentTask>());

    final urgentTask = task as UrgentTask;

    expect(urgentTask.urgencyLevel, 5);
  });

  test('serializes concurrent completion toggles for the same task', () async {
    final task = await service.addTask(
      title: 'Review changes',
      priority: Priority.medium,
    );

    await Future.wait([
      service.toggleTaskCompletion(task.id),
      service.toggleTaskCompletion(task.id),
    ]);

    expect((await service.repository.getById(task.id)).completed, isFalse);
  });

  test('sorts urgent tasks before non-urgent tasks by priority', () async {
    await service.addTask(title: 'High priority', priority: Priority.high);
    final urgent = await service.addTask(
      title: 'Urgent task',
      priority: Priority.low,
      urgent: true,
      urgencyLevel: 2,
    );

    final tasks = await service.getTasks();

    expect(tasks.first.id, urgent.id);
  });
}
