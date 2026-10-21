import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager/models/basic_task.dart';
import 'package:task_manager/models/priority.dart';
import 'package:task_manager/models/urgent_task.dart';
import 'package:task_manager/repositories/shared_preferences_task_repository.dart';

void main() {
  late SharedPreferences preferences;
  late SharedPreferencesTaskRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    repository = SharedPreferencesTaskRepository(preferences);
  });

  test('restores tasks after the repository is recreated', () async {
    final dueDate = DateTime(2026, 10, 20);
    await repository.add(
      UrgentTask(1, 'Prepare demo', Priority.high, dueDate, true, 4),
    );

    final restartedRepository = SharedPreferencesTaskRepository(preferences);
    final tasks = await restartedRepository.getAll();

    expect(tasks, hasLength(1));
    expect(tasks.single.title, 'Prepare demo');
    expect(tasks.single.completed, isTrue);
    expect(tasks.single.dueDate, dueDate);
    expect(tasks.single, isA<UrgentTask>());
    expect((tasks.single as UrgentTask).urgencyLevel, 4);
  });

  test('updates and deletes stored tasks', () async {
    await repository.add(BasicTask(1, 'Draft', Priority.low, null, false));
    await repository.update(
      BasicTask(1, 'Final draft', Priority.medium, null, true),
    );

    final updated = await repository.getById(1);
    expect(updated.title, 'Final draft');
    expect(updated.priority, Priority.medium);
    expect(updated.completed, isTrue);

    await repository.delete(1);
    expect(await repository.getAll(), isEmpty);
  });
}
