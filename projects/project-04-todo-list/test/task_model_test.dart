import 'package:test/test.dart';

import 'package:task_manager/models/basic_task.dart';
import 'package:task_manager/models/priority.dart';
import 'package:task_manager/models/urgent_task.dart';

void main() {
  group('Task models', () {
    test('BasicTask should serialize to JSON', () {
      final task = BasicTask(1, 'Learn Dart', Priority.high, null, false);

      final json = task.toJson();

      expect(json['id'], 1);
      expect(json['title'], 'Learn Dart');
      expect(json['priority'], 'high');
      expect(json['completed'], false);
      expect(json['type'], 'basic');
    });

    test('UrgentTask should serialize urgency level', () {
      final task = UrgentTask(2, 'Fix bug', Priority.high, null, false, 5);

      final json = task.toJson();

      expect(json['type'], 'urgent');
      expect(json['urgencyLevel'], 5);
    });
  });
}
