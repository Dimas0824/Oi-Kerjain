import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/ui_palette.dart';
import '../../../core/constants/ui_typography.dart';
import '../../../model/repeat_rule.dart';
import '../../../model/task.dart';
import '../../../model/task_category.dart';
import 'neu_surface.dart';
import 'priority_indicator.dart';

class TaskTimelineItem extends StatelessWidget {
  const TaskTimelineItem({
    super.key,
    required this.task,
    required this.now,
    required this.onTap,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        !task.isDone && task.dueAtEpochMillis < now.millisecondsSinceEpoch;
    final hasDescription = task.description.trim().isNotEmpty;
    final categoryIcon = task.category == TaskCategory.work
        ? Icons.work_rounded
        : Icons.person_rounded;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 46,
          child: Column(
            children: <Widget>[
              Text(
                _timeLabel(task.dueAt),
                style: UITypography.captionStrong.copyWith(
                  color: UIPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: UIPalette.textSecondary.withValues(alpha: 0.28),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 2,
                height: 44,
                color: UIPalette.textMuted.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NeuSurface(
            key: Key('task-card-${task.id}'),
            radius: 22,
            onTap: onTap,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Opacity(
                    opacity: task.isDone ? 0.42 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300.withValues(
                                  alpha: 0.45,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    categoryIcon,
                                    size: 10,
                                    color: UIPalette.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.category.label,
                                    style: UITypography.caption.copyWith(
                                      color: UIPalette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            PriorityIndicator(priority: task.priority),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.title,
                          style: UITypography.bodyStrong.copyWith(
                            fontSize: 15,
                            color: UIPalette.textPrimary,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            decorationThickness: 2,
                          ),
                        ),
                        if (hasDescription) ...<Widget>[
                          const SizedBox(height: 5),
                          Text(
                            task.description.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: UITypography.body.copyWith(
                              fontSize: 12,
                              height: 1.3,
                              color: UIPalette.textSecondary.withValues(
                                alpha: 0.95,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 9),
                        Row(
                          children: <Widget>[
                            if (task.repeatRule != RepeatRule.none) ...<Widget>[
                              const Icon(
                                Icons.autorenew_rounded,
                                size: 12,
                                color: UIPalette.textMuted,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                task.repeatRule.label,
                                style: UITypography.caption,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _timeLabel(task.dueAt),
                                style: UITypography.caption,
                              ),
                            ),
                            if (isOverdue)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Lewat tenggat',
                                    style: UITypography.caption,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                NeuSurface(
                  radius: 12,
                  pressed: true,
                  padding: const EdgeInsets.all(9),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: task.isDone
                        ? Icon(
                            Icons.check_rounded,
                            key: Key('task-check-icon-${task.id}'),
                            size: 16,
                            color: UIPalette.accent,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _timeLabel(DateTime dueAt) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = DateTime(now.year, now.month, now.day - 1);

    if (dueAt.isBefore(todayStart)) {
      if (dueAt.isAfter(yesterdayStart)) {
        return 'Kemarin';
      }
      return DateFormat('dd/MM').format(dueAt);
    }

    if (dueAt.minute == 0) {
      return dueAt.hour.toString().padLeft(2, '0');
    }

    return DateFormat('HH:mm').format(dueAt);
  }
}
