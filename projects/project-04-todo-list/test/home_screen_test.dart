import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_manager/main.dart';
import 'package:task_manager/models/basic_task.dart';
import 'package:task_manager/models/priority.dart';
import 'package:task_manager/models/urgent_task.dart';
import 'package:task_manager/repositories/shared_preferences_task_repository.dart';
import 'package:task_manager/screens/home_screen.dart';
import 'package:task_manager/services/task_service.dart';

void main() {
  late SharedPreferences preferences;
  late SharedPreferencesTaskRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    repository = SharedPreferencesTaskRepository(preferences);
  });

  testWidgets('shows an empty state and creates a task', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(service: TaskService(repository))),
    );
    await tester.pumpAndSettle();

    expect(find.text('A little room for your ideas'), findsOneWidget);
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Prepare the presentation',
    );
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Prepare the presentation'), findsOneWidget);
    expect(await repository.getAll(), hasLength(1));
  });

  testWidgets('restores tasks when the app is restarted', (tester) async {
    await tester.pumpWidget(const TaskManagerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Review the report');
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(find.text('Review the report'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const TaskManagerApp());
    await tester.pumpAndSettle();

    expect(find.text('Review the report'), findsOneWidget);
  });

  testWidgets('filters tasks between pending and completed', (tester) async {
    await repository.add(
      BasicTask(1, 'Completed task', Priority.low, null, true),
    );
    await repository.add(
      BasicTask(2, 'Pending task', Priority.low, null, false),
    );
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(service: TaskService(repository))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Completed task'), findsOneWidget);
    expect(find.text('Pending task'), findsOneWidget);

    await tester.tap(find.text('To do'));
    await tester.pumpAndSettle();
    expect(find.text('Pending task'), findsOneWidget);
    expect(find.text('Completed task'), findsNothing);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Completed task'), findsOneWidget);
    expect(find.text('Pending task'), findsNothing);
  });

  testWidgets('displays priority and urgency labels in English', (
    tester,
  ) async {
    await repository.add(
      UrgentTask(1, 'Review the report', Priority.medium, null, false, 4),
    );
    await repository.add(
      BasicTask(2, 'Plan the week', Priority.low, null, false),
    );
    await repository.add(
      BasicTask(3, 'Submit the assignment', Priority.high, null, false),
    );
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(service: TaskService(repository))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Urgent'), findsOneWidget);
  });

  testWidgets('edits, completes, and deletes a task', (tester) async {
    await repository.add(
      BasicTask(1, 'Plan the week', Priority.low, null, false),
    );
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(service: TaskService(repository))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan the week'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Prepare for review');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Prepare for review'), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel('Mark Prepare for review as completed'),
    );
    await tester.pumpAndSettle();
    expect((await repository.getById(1)).completed, isTrue);

    await tester.tap(find.byTooltip('Task options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await repository.getAll(), isEmpty);
    expect(find.text('A little room for your ideas'), findsOneWidget);
  });

  testWidgets('opens the date picker for an overdue task', (tester) async {
    await repository.add(
      BasicTask(1, 'Overdue task', Priority.low, DateTime(2000, 1, 1), false),
    );
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(service: TaskService(repository))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Overdue task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('01/01/2000'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
