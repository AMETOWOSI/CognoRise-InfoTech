import 'dart:io';

import 'package:task_manager/models/priority.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/models/urgent_task.dart';
import 'package:task_manager/repositories/task_repository.dart';
import 'package:task_manager/services/task_service.dart';
import 'package:task_manager/exceptions/task_exception.dart';

void main() async {
  final repository = TaskRepository();
  final service = TaskService(repository);

  while (true) {
    print('\n==============================');
    print('       TASK MANAGER');
    print('==============================');
    print('1. Add a task');
    print('2. List tasks');
    print('3. Mark task as completed');
    print('4. Delete a task');
    print('5. Exit');
    print('==============================');

    stdout.write('Choose an option: ');
    final choice = stdin.readLineSync();

    try {
      switch (choice) {
        case '1':
          await addTask(service);
          break;
        case '2':
          await listTasks(service);
          break;
        case '3':
          await completeTask(service);
          break;
        case '4':
          await deleteTask(service);
          break;
        case '5':
          print('Goodbye!');
          return;
        default:
          print('Invalid option.');
      }
    } on TaskException catch (e) {
      print('Error: $e');
    } on FormatException catch (e) {
      print('Invalid data: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
    }
  }
}

Future<void> addTask(TaskService service) async {
  stdout.write('Title: ');
  final title = stdin.readLineSync() ?? '';

  stdout.write('Priority (low/medium/high): ');
  final priorityInput = (stdin.readLineSync() ?? '').toLowerCase();

  final priority = Priority.values.firstWhere(
    (p) => p.name == priorityInput,
    orElse: () => throw InvalidTaskException(
      'Invalid priority. Use low, medium or high.',
    ),
  );

  stdout.write('Due date (YYYY-MM-DD) or leave empty: ');
  final dateInput = stdin.readLineSync() ?? '';

  DateTime? dueDate;

  if (dateInput.trim().isNotEmpty) {
    dueDate = DateTime.tryParse(dateInput);

    if (dueDate == null) {
      throw InvalidTaskException('Invalid date format.');
    }
  }

  stdout.write('Is this an urgent task? (y/n): ');
  final urgentInput = (stdin.readLineSync() ?? '').toLowerCase();

  final urgent = urgentInput == 'y';

  int urgencyLevel = 1;

  if (urgent) {
    stdout.write('Urgency level (1-5): ');

    urgencyLevel = int.tryParse(stdin.readLineSync() ?? '') ?? 0;

    if (urgencyLevel < 1 || urgencyLevel > 5) {
      throw InvalidTaskException('Urgency level must be between 1 and 5.');
    }
  }

  final task = await service.addTask(
    title: title,
    priority: priority,
    dueDate: dueDate,
    urgent: urgent,
    urgencyLevel: urgencyLevel,
  );

  print('Task #${task.id} created successfully.');
}

Future<void> listTasks(TaskService service) async {
  stdout.write('Sort by priority or date? [priority/date]: ');

  final sortBy = (stdin.readLineSync() ?? 'priority').toLowerCase();

  final tasks = await service.getTasks(
    sortBy: sortBy == 'date' ? 'date' : 'priority',
  );

  if (tasks.isEmpty) {
    print('No tasks found.');
    return;
  }

  print('\n------------------------------');

  for (final task in tasks) {
    printTask(task);
  }

  print('------------------------------');
}

void printTask(Task task) {
  final status = task.completed ? 'DONE' : 'TODO';

  final dueDate = task.dueDate == null
      ? 'No deadline'
      : task.dueDate!.toIso8601String().split('T').first;

  print(
    '#${task.id} | '
    '${task.title} | '
    'Priority: ${task.priority.name} | '
    'Due: $dueDate | '
    'Status: $status',
  );

  if (task is UrgentTask) {
    print('   Urgent task - Level: ${task.urgencyLevel}');
  }
}

Future<void> completeTask(TaskService service) async {
  stdout.write('Enter task ID: ');

  final id = int.tryParse(stdin.readLineSync() ?? '');

  if (id == null) {
    throw InvalidTaskException('Task ID must be a number.');
  }

  final task = await service.completeTask(id);

  print('Task #${task.id} marked as completed.');
}

Future<void> deleteTask(TaskService service) async {
  stdout.write('Enter task ID: ');

  final id = int.tryParse(stdin.readLineSync() ?? '');

  if (id == null) {
    throw InvalidTaskException('Task ID must be a number.');
  }

  await service.deleteTask(id);

  print('Task #$id deleted successfully.');
}
