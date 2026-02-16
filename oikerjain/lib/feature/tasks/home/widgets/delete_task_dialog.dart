import 'package:flutter/material.dart';

import '../../../../core/constants/ui_palette.dart';
import '../../../../core/constants/ui_typography.dart';
import '../../components/neu_button.dart';
import '../../components/neu_surface.dart';

class DeleteTaskDialog extends StatelessWidget {
  const DeleteTaskDialog({super.key, required this.taskTitle});

  final String taskTitle;

  @override
  Widget build(BuildContext context) {
    final trimmedTitle = taskTitle.trim();
    final titlePreview = trimmedTitle.isEmpty ? '(tanpa judul)' : trimmedTitle;

    return Dialog(
      key: const Key('delete-task-dialog'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: NeuSurface(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                NeuSurface(
                  pressed: true,
                  radius: 12,
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Hapus tugas?',
                  style: UITypography.bodyStrong.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            NeuSurface(
              pressed: true,
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                'Tugas "$titlePreview" akan dihapus.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: UITypography.body.copyWith(color: UIPalette.textMuted),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: NeuButton(
                    key: const Key('delete-task-cancel-button'),
                    onTap: () => Navigator.of(context).pop(false),
                    radius: 12,
                    height: 40,
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NeuButton(
                    key: const Key('delete-task-confirm-button'),
                    onTap: () => Navigator.of(context).pop(true),
                    active: true,
                    foregroundColor: Colors.redAccent,
                    radius: 12,
                    height: 40,
                    child: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
