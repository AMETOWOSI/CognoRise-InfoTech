import 'package:flutter/material.dart';
import 'package:task_manager/app_theme.dart';
import 'package:task_manager/models/priority.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/models/urgent_task.dart';

class TaskDraft {
  final String title;
  final Priority priority;
  final DateTime? dueDate;
  final bool urgent;
  final int urgencyLevel;

  const TaskDraft({
    required this.title,
    required this.priority,
    required this.dueDate,
    required this.urgent,
    required this.urgencyLevel,
  });
}

Future<TaskDraft?> showTaskEditor(BuildContext context, {Task? task}) =>
    showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => TaskEditorSheet(task: task),
    );

class TaskEditorSheet extends StatefulWidget {
  final Task? task;

  const TaskEditorSheet({this.task, super.key});

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late Priority _priority;
  late DateTime? _dueDate;
  late bool _urgent;
  late int _urgencyLevel;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _priority = task?.priority ?? Priority.medium;
    _dueDate = task?.dueDate;
    _urgent = task is UrgentTask;
    _urgencyLevel = task is UrgentTask ? task.urgencyLevel : 3;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 13, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3E2E8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.task == null ? 'New task' : 'Edit task',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'One small step at a time.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 23),
              const _FieldLabel('TITLE'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'e.g. Prepare the presentation',
                  counterText: '',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a title for your task.'
                    : null,
              ),
              const SizedBox(height: 19),
              const _FieldLabel('PRIORITY'),
              const SizedBox(height: 9),
              Wrap(
                spacing: 9,
                children: Priority.values.map((priority) {
                  final selected = _priority == priority;
                  return ChoiceChip(
                    label: Text(_priorityLabel(priority)),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: AppColors.softViolet,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.violet : AppColors.mutedInk,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: selected ? AppColors.violet : AppColors.line,
                    ),
                    onSelected: (_) => setState(() => _priority = priority),
                  );
                }).toList(),
              ),
              const SizedBox(height: 19),
              const _FieldLabel('DUE DATE'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(
                  _dueDate == null ? 'Add a due date' : _formatDate(_dueDate!),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.line),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
              if (_dueDate != null)
                TextButton.icon(
                  onPressed: () => setState(() => _dueDate = null),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Remove due date'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mutedInk,
                  ),
                ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Urgent task',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text('Give this task extra priority'),
                value: _urgent,
                activeTrackColor: AppColors.violet,
                onChanged: (value) => setState(() => _urgent = value),
              ),
              if (_urgent)
                Row(
                  children: [
                    const Text(
                      'Urgency level',
                      style: TextStyle(
                        color: AppColors.mutedInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _urgencyLevel,
                      underline: const SizedBox.shrink(),
                      items: List.generate(
                        5,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1} / 5'),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _urgencyLevel = value);
                        }
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: Icon(
                    widget.task == null
                        ? Icons.add_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(
                    widget.task == null ? 'Add task' : 'Save changes',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final existingDate = _dueDate;
    final initialDate = existingDate != null && !existingDate.isBefore(today)
        ? existingDate
        : today;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 10),
      helpText: 'Choose a due date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );
    if (selected != null && mounted) {
      setState(() => _dueDate = selected);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      TaskDraft(
        title: _titleController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        urgent: _urgent,
        urgencyLevel: _urgencyLevel,
      ),
    );
  }

  static String _priorityLabel(Priority priority) => switch (priority) {
    Priority.low => 'Low',
    Priority.medium => 'Medium',
    Priority.high => 'High',
  };

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.mutedInk,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.15,
    ),
  );
}
