import 'task.dart';
import 'urgent_task.dart';
import 'basic_task.dart';

class TaskFactory {
  static Task fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'urgent':
        return UrgentTask.fromJson(json);

      case 'basic':
        return BasicTask.fromJson(json);

      default:
        throw FormatException('Unknown task type: ${json['type']}');
    }
  }
}
