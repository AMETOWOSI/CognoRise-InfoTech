import 'dart:async';

import 'package:task_manager/exceptions/task_exception.dart';
import 'package:task_manager/models/basic_task.dart';
import 'package:task_manager/models/priority.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/models/urgent_task.dart';
import 'package:task_manager/repositories/repository.dart';

class TaskService {
  final Repository<Task> repository;
  final Map<int, Future<void>> _completionQueues = {};

  TaskService(this.repository);

  Future<Task> addTask({
    required String title,
    required Priority priority,
    DateTime? dueDate,
    bool urgent = false,
    int urgencyLevel = 1,
  }) async {
    if (title.trim().isEmpty) {
      throw InvalidTaskException('Task title cannot be empty.');
    }
    if (urgent && (urgencyLevel < 1 || urgencyLevel > 5)) {
      throw InvalidTaskException('Urgency level must be between 1 and 5.');
    }

    final tasks = await repository.getAll();

    final nextId = tasks.isEmpty
        ? 1
        : tasks.map((task) => task.id).reduce((a, b) => a > b ? a : b) + 1;

    final Task task;

    if (urgent) {
      task = UrgentTask(
        nextId,
        title.trim(),
        priority,
        dueDate,
        false,
        urgencyLevel,
      );
    } else {
      task = BasicTask(nextId, title.trim(), priority, dueDate, false);
    }

    return repository.add(task);
  }

  Future<List<Task>> getTasks({String sortBy = 'priority'}) async {
    final tasks = (await repository.getAll()).toList();

    if (sortBy == 'date') {
      tasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) {
          return 0;
        }

        if (a.dueDate == null) {
          return 1;
        }

        if (b.dueDate == null) {
          return -1;
        }

        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else {
      tasks.sort((a, b) {
        final aUrgency = a is UrgentTask ? a.urgencyLevel : 0;
        final bUrgency = b is UrgentTask ? b.urgencyLevel : 0;
        final urgencyComparison = bUrgency.compareTo(aUrgency);
        if (urgencyComparison != 0) {
          return urgencyComparison;
        }
        return _priorityValue(b.priority).compareTo(_priorityValue(a.priority));
      });
    }

    return tasks;
  }

  Future<Task> completeTask(int id) async {
    final task = await repository.getById(id);

    task.completed = true;

    return repository.update(task);
  }

  Future<Task> toggleTaskCompletion(int id) {
    final completer = Completer<Task>();
    final previous = _completionQueues[id] ?? Future<void>.value();
    final operation = previous.then((_) async {
      try {
        final task = await repository.getById(id);
        task.completed = !task.completed;
        completer.complete(await repository.update(task));
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    final queueTail = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    _completionQueues[id] = queueTail;

    return completer.future.whenComplete(() {
      if (identical(_completionQueues[id], queueTail)) {
        _completionQueues.remove(id);
      }
    });
  }

  Future<Task> updateTask({
    required int id,
    required String title,
    required Priority priority,
    required DateTime? dueDate,
    bool? urgent,
    int? urgencyLevel,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw InvalidTaskException('Task title cannot be empty.');
    }

    final existing = await repository.getById(id);
    final shouldBeUrgent = urgent ?? (existing is UrgentTask);
    final Task updated;

    if (shouldBeUrgent) {
      final level =
          urgencyLevel ?? (existing is UrgentTask ? existing.urgencyLevel : 1);
      if (level < 1 || level > 5) {
        throw InvalidTaskException('Urgency level must be between 1 and 5.');
      }
      updated = UrgentTask(
        id,
        normalizedTitle,
        priority,
        dueDate,
        existing.completed,
        level,
      );
    } else {
      updated = BasicTask(
        id,
        normalizedTitle,
        priority,
        dueDate,
        existing.completed,
      );
    }

    return repository.update(updated);
  }

  Future<void> deleteTask(int id) async {
    await repository.delete(id);
  }

  int _priorityValue(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.high:
        return 3;
    }
  }
}
