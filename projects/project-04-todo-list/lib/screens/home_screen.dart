import 'dart:async';

import 'package:flutter/material.dart';
import 'package:task_manager/app_theme.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/services/task_service.dart';
import 'package:task_manager/widgets/task_card.dart';
import 'package:task_manager/widgets/task_editor_sheet.dart';

enum TaskFilter { all, pending, completed }

class HomeScreen extends StatefulWidget {
  final TaskService service;

  const HomeScreen({required this.service, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  String _sortBy = 'priority';
  bool _loading = true;
  String? _loadError;
  Timer? _deleteMessageTimer;

  @override
  void dispose() {
    _deleteMessageTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  int get _completedCount => _tasks.where((task) => task.completed).length;

  List<Task> get _visibleTasks {
    final filtered = switch (_filter) {
      TaskFilter.all => _tasks,
      TaskFilter.pending => _tasks.where((task) => !task.completed).toList(),
      TaskFilter.completed => _tasks.where((task) => task.completed).toList(),
    };
    return filtered;
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final tasks = await widget.service.getTasks(sortBy: _sortBy);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Your tasks could not be loaded. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _openEditor([Task? task]) async {
    final draft = await showTaskEditor(context, task: task);
    if (draft == null || !mounted) return;

    try {
      if (task == null) {
        await widget.service.addTask(
          title: draft.title,
          priority: draft.priority,
          dueDate: draft.dueDate,
          urgent: draft.urgent,
          urgencyLevel: draft.urgencyLevel,
        );
      } else {
        await widget.service.updateTask(
          id: task.id,
          title: draft.title,
          priority: draft.priority,
          dueDate: draft.dueDate,
          urgent: draft.urgent,
          urgencyLevel: draft.urgencyLevel,
        );
      }
      await _loadTasks();
      if (mounted) {
        _showMessage(task == null ? 'Task added.' : 'Task updated.');
      }
    } catch (error) {
      _showMessage('The task could not be saved. Please try again.');
    }
  }

  Future<void> _toggleTask(Task task) async {
    try {
      await widget.service.toggleTaskCompletion(task.id);
      await _loadTasks();
    } catch (error) {
      _showMessage('The task status could not be changed. Please try again.');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await widget.service.deleteTask(task.id);
      await _loadTasks();
      if (!mounted) return;
      _deleteMessageTimer?.cancel();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task deleted.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: const Color(0xFFD5CEFF),
            onPressed: () {
              _deleteMessageTimer?.cancel();
              _restoreTask(task);
            },
          ),
        ),
      );
      _deleteMessageTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      });
    } catch (error) {
      _showMessage('The task could not be deleted. Please try again.');
    }
  }

  Future<void> _restoreTask(Task task) async {
    try {
      await widget.service.repository.add(task);
      await _loadTasks();
    } catch (error) {
      _showMessage('The task could not be restored. Please try again.');
    }
  }

  Future<void> _changeSort(String sortBy) async {
    if (_sortBy == sortBy) return;
    setState(() => _sortBy = sortBy);
    await _loadTasks();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    _deleteMessageTimer?.cancel();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final progress = _tasks.isEmpty ? 0.0 : _completedCount / _tasks.length;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.violet,
          onRefresh: _loadTasks,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildHeader(progress),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 27, 22, 14),
                      child: _buildListHeading(),
                    ),
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.violet),
                  ),
                )
              else if (_loadError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(message: _loadError!, onRetry: _loadTasks),
                )
              else if (_visibleTasks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    filter: _filter,
                    onAdd: () => _openEditor(),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        child: Column(
                          children: _visibleTasks
                              .map(
                                (task) => TaskCard(
                                  key: ValueKey(task.id),
                                  task: task,
                                  onToggle: () => _toggleTask(task),
                                  onEdit: () => _openEditor(task),
                                  onDelete: () => _deleteTask(task),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New task',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    final now = DateTime.now();
    final date = '${_weekday(now.weekday)} ${now.day} ${_month(now.month)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(23, 21, 23, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF242740), Color(0xFF343453)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -65,
            child: Container(
              width: 175,
              height: 175,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.035),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -90,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 24,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: Color(0xFFD5CEFF),
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'T A S K S',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 27),
              Text(
                _greeting(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Ready to get organized?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.13),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFC6EF91),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Text(
                    '$_completedCount/${_tasks.length} completed',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListHeading() {
    final counts = [
      _tasks.length,
      _tasks.where((task) => !task.completed).length,
      _completedCount,
    ];
    const filters = [
      (TaskFilter.all, 'All'),
      (TaskFilter.pending, 'To do'),
      (TaskFilter.completed, 'Completed'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your tasks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _tasks.isEmpty
                        ? 'Start with one small step.'
                        : '$_completedCount of ${_tasks.length} tasks completed',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Sort tasks',
              onSelected: _changeSort,
              itemBuilder: (context) => [
                CheckedPopupMenuItem(
                  value: 'priority',
                  checked: _sortBy == 'priority',
                  child: const Text('Priority'),
                ),
                CheckedPopupMenuItem(
                  value: 'date',
                  checked: _sortBy == 'date',
                  child: const Text('Due date'),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.swap_vert_rounded,
                      size: 18,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _sortBy == 'priority' ? 'Priority' : 'Due date',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(filters.length, (index) {
              final filter = filters[index].$1;
              final selected = _filter == filter;
              return Padding(
                padding: EdgeInsets.only(
                  right: index == filters.length - 1 ? 0 : 8,
                ),
                child: ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = filter),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(filters[index].$2),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.18)
                              : AppColors.canvas,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '${counts[index]}',
                          style: TextStyle(
                            fontSize: 11,
                            color: selected ? Colors.white : AppColors.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  selectedColor: AppColors.ink,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? AppColors.ink : AppColors.line,
                  ),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.mutedInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 7,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  static String _weekday(int weekday) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][weekday - 1];

  static String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _EmptyState extends StatelessWidget {
  final TaskFilter filter;
  final VoidCallback onAdd;

  const _EmptyState({required this.filter, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final noTasks = filter == TaskFilter.all;
    final title = switch (filter) {
      TaskFilter.all => 'A little room for your ideas',
      TaskFilter.pending => 'You are all caught up',
      TaskFilter.completed => 'No completed tasks yet',
    };
    final subtitle = switch (filter) {
      TaskFilter.all => 'Add a task and turn your plans into action.',
      TaskFilter.pending => 'There are no pending tasks. Enjoy the progress.',
      TaskFilter.completed => 'Completed tasks will appear here.',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 20, 36, 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: AppColors.softViolet,
                shape: BoxShape.circle,
              ),
              child: Icon(
                noTasks
                    ? Icons.edit_note_rounded
                    : filter == TaskFilter.pending
                    ? Icons.done_all_rounded
                    : Icons.check_circle_outline_rounded,
                size: 42,
                color: AppColors.violet,
              ),
            ),
            const SizedBox(height: 19),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(subtitle, textAlign: TextAlign.center),
            if (noTasks) ...[
              const SizedBox(height: 19),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create your first task'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.violet,
                  side: const BorderSide(color: AppColors.violet),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: AppColors.mutedInk,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
