import 'package:flutter/material.dart';
import 'package:task_manager/app_theme.dart';
import 'package:task_manager/models/priority.dart';
import 'package:task_manager/models/task.dart';
import 'package:task_manager/models/urgent_task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      Priority.high => const Color(0xFFCB6858),
      Priority.medium => const Color(0xFFB87937),
      Priority.low => AppColors.green,
    };
    final dateLabel = task.dueDate == null ? null : _formatDate(task.dueDate!);
    final urgent = task is UrgentTask;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE8E7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Color(0xFFB64C49),
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: task.completed ? AppColors.line : Colors.white,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF292A42).withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 8, 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    button: true,
                    label: task.completed
                        ? 'Mark ${task.title} as to do'
                        : 'Mark ${task.title} as completed',
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onToggle,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            width: 27,
                            height: 27,
                            decoration: BoxDecoration(
                              color: task.completed
                                  ? AppColors.green
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: task.completed
                                    ? AppColors.green
                                    : const Color(0xFFD3D3DC),
                                width: 1.7,
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: task.completed
                                  ? const Icon(
                                      Icons.check_rounded,
                                      key: ValueKey('checked'),
                                      size: 19,
                                      color: Colors.white,
                                    )
                                  : const SizedBox(
                                      key: ValueKey('unchecked'),
                                      width: 19,
                                      height: 19,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            color: task.completed
                                ? AppColors.mutedInk
                                : AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.mutedInk,
                          ),
                          child: Text(task.title),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          children: [
                            _MetaPill(
                              label: _priorityLabel(task.priority),
                              color: priorityColor,
                              icon: Icons.flag_rounded,
                            ),
                            if (dateLabel != null)
                              _MetaPill(
                                label: dateLabel,
                                color: AppColors.mutedInk,
                                icon: Icons.calendar_today_rounded,
                              ),
                            if (urgent)
                              const _MetaPill(
                                label: 'Urgent',
                                color: AppColors.orange,
                                icon: Icons.bolt_rounded,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Task options',
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.mutedInk,
                    ),
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _priorityLabel(Priority priority) => switch (priority) {
    Priority.high => 'High',
    Priority.medium => 'Medium',
    Priority.low => 'Low',
  };

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _MetaPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
