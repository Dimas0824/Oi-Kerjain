import 'package:flutter/material.dart';

import '../../../model/task_category.dart';
import 'neu_button.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.active,
    required this.onTap,
  });

  final TaskCategory category;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = category == TaskCategory.work
        ? Icons.work_rounded
        : Icons.person_rounded;

    return NeuButton(
      active: active,
      onTap: onTap,
      radius: 12,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(category.label),
        ],
      ),
    );
  }
}
