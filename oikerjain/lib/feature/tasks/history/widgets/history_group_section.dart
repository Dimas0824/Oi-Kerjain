import 'package:flutter/material.dart';

import '../../../../core/constants/ui_typography.dart';
import '../../../../core/utils/indonesian_date_formatter.dart';
import '../../../../model/task.dart';
import '../../home/widgets/swipe_background.dart';
import 'history_task_cartridge.dart';

class HistoryGroupSection extends StatelessWidget {
  const HistoryGroupSection({
    super.key,
    required this.createdDate,
    required this.tasks,
    required this.onOpen,
    required this.onUndo,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime createdDate;
  final List<Task> tasks;
  final Future<void> Function(Task task) onOpen;
  final ValueChanged<String> onUndo;
  final Future<void> Function(Task task) onEdit;
  final Future<void> Function(Task task) onDelete;

  @override
  Widget build(BuildContext context) {
    final sortedTasks = List<Task>.from(tasks)
      ..sort(
        (a, b) =>
            (b.completedAtEpochMillis ?? 0).compareTo(a.completedAtEpochMillis ?? 0),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          IndonesianDateFormatter.fullDate(createdDate),
          key: Key('history-group-${createdDate.millisecondsSinceEpoch}'),
          style: UITypography.sectionLabel,
        ),
        const SizedBox(height: 8),
        ...sortedTasks.map((task) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: Key('history-task-dismiss-${task.id}'),
              direction: DismissDirection.horizontal,
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  await onEdit(task);
                  return false;
                }

                await onDelete(task);
                return false;
              },
              background: const SwipeBackground(
                icon: Icons.edit_rounded,
                alignment: Alignment.centerLeft,
                color: Colors.blueGrey,
                label: 'Ubah',
              ),
              secondaryBackground: const SwipeBackground(
                icon: Icons.delete_rounded,
                alignment: Alignment.centerRight,
                color: Colors.redAccent,
                label: 'Hapus',
              ),
              child: HistoryTaskCartridge(
                task: task,
                onTap: () => onOpen(task),
                onUndo: () => onUndo(task.id),
              ),
            ),
          );
        }),
      ],
    );
  }
}
