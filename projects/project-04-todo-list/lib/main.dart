import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:task_manager/app_theme.dart';
import 'package:task_manager/repositories/shared_preferences_task_repository.dart';
import 'package:task_manager/screens/home_screen.dart';
import 'package:task_manager/services/task_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  late final Future<SharedPreferencesTaskRepository> _repositoryFuture;

  @override
  void initState() {
    super.initState();
    _repositoryFuture = SharedPreferencesTaskRepository.create();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Task List',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    locale: const Locale('en'),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('en')],
    home: FutureBuilder<SharedPreferencesTaskRepository>(
      future: _repositoryFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _StartupErrorScreen();
        }
        if (!snapshot.hasData) {
          return const _StartupScreen();
        }
        return HomeScreen(service: TaskService(snapshot.data!));
      },
    ),
  );
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: CircularProgressIndicator(color: AppColors.violet)),
  );
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 42, color: Colors.red),
            SizedBox(height: 14),
            Text('The app could not start.', textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
