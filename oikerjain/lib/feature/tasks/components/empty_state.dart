import 'package:flutter/material.dart';

import '../../../core/constants/ui_typography.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Opacity(
        opacity: 0.45,
        child: Text('Belum ada tugas.', style: UITypography.body),
      ),
    );
  }
}
