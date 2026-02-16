import 'package:flutter/material.dart';

import '../../../core/constants/ui_palette.dart';
import 'neu_button.dart';

class FabAddButton extends StatelessWidget {
  const FabAddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeuButton(
      key: const Key('fab-add-task'),
      onTap: onTap,
      radius: 18,
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(0),
      foregroundColor: UIPalette.accent,
      child: const Icon(Icons.add_rounded, size: 34),
    );
  }
}
