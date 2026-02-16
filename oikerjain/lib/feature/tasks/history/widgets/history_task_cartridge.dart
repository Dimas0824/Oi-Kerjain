import 'package:flutter/material.dart';

import '../../../../core/constants/ui_palette.dart';
import '../../../../core/constants/ui_typography.dart';
import '../../../../core/utils/indonesian_date_formatter.dart';
import '../../../../model/task.dart';
import '../../components/neu_surface.dart';

class HistoryTaskCartridge extends StatelessWidget {
  const HistoryTaskCartridge({
    super.key,
    required this.task,
    required this.onUndo,
  });

  final Task task;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final completedAt = task.completedAt;
    final completedLabel = completedAt == null
        ? '-'
        : IndonesianDateFormatter.time24(completedAt);

    return NeuSurface(
      key: Key('history-task-card-${task.id}'),
      radius: 16,
      onTap: onUndo,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: UITypography.bodyStrong.copyWith(
                    decoration: TextDecoration.lineThrough,
                    decorationThickness: 2,
                  ),
                ),
                if (task.description.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    task.description.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: UITypography.captionStrong,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Selesai: $completedLabel',
                  style: UITypography.captionStrong.copyWith(
                    color: UIPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          NeuSurface(
            pressed: true,
            radius: 10,
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.undo_rounded,
              size: 16,
              color: UIPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
