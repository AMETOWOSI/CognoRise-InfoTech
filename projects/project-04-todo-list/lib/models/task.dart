import 'package:task_manager/models/priority.dart';

abstract class Task {
  final int id; // Cannot be reassigned after construction.
  String title;
  Priority priority;
  DateTime? dueDate;
  bool completed;

  Task(this.id, this.title, this.priority, this.dueDate, this.completed);

  Map<String, dynamic> toJson();
}
