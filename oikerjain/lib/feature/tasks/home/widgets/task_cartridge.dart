import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/ui_palette.dart';
import '../../../../model/task.dart';
import '../../../../model/task_category.dart';
import '../../../../model/task_priority.dart';
import '../../components/neu_surface.dart';

class TaskCartridge extends StatelessWidget {
  const TaskCartridge({
    super.key,
    required this.task,
    required this.isOverdue,
    required this.onToggle,
  });

  final Task task;
  final bool isOverdue;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final sideColor = task.category == TaskCategory.work
        ? Colors.blueAccent
        : Colors.orangeAccent;

    return NeuSurface(
      key: Key('task-card-${task.id}'),
      radius: 16,
      onTap: onToggle,
      padding: const EdgeInsets.all(0),
      child: Row(
        children: <Widget>[
          Container(
            width: 6,
            height: 104,
            decoration: BoxDecoration(
              color: sideColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeInOutCubic,
                opacity: task.isDone ? 0.55 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeInOutCubic,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationThickness: 2,
                              color: UIPalette.textSecondary,
                            ),
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (task.priority.rank == 3)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (task.description.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        task.description.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: UIPalette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    NeuSurface(
                      pressed: true,
                      radius: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(task.dueAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: UIPalette.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(task.dueAt),
                            style: const TextStyle(
                              color: UIPalette.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            task.category.label,
                            style: const TextStyle(
                              color: UIPalette.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOverdue)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Lewat tenggat',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 52,
            height: 104,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: UIPalette.textMuted.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Center(
              child: NeuSurface(
                pressed: task.isDone,
                radius: 10,
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.9,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: task.isDone
                        ? Icon(
                            Icons.check_rounded,
                            key: Key('task-check-icon-${task.id}'),
                            size: 16,
                            color: Colors.white,
                          )
                        : const SizedBox.shrink(key: ValueKey<String>('empty')),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
