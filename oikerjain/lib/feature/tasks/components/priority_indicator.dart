import 'package:flutter/material.dart';

import '../../../core/constants/ui_palette.dart';
import '../../../core/constants/ui_typography.dart';
import '../../../model/task_priority.dart';

class PriorityIndicator extends StatelessWidget {
  const PriorityIndicator({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final isHigh = priority == TaskPriority.high;
    final isMedium = priority == TaskPriority.medium;

    return Opacity(
      opacity: isHigh ? 1 : (isMedium ? 0.7 : 0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.flag_rounded,
            size: 12,
            color: UIPalette.textSecondary,
          ),
          const SizedBox(width: 2),
          Text(
            priority.label,
            style: UITypography.caption.copyWith(
              color: UIPalette.textSecondary,
              fontWeight: isHigh ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
