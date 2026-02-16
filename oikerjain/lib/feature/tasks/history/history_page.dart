import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/constants/ui_palette.dart';
import '../../../core/constants/ui_typography.dart';
import '../../../core/utils/indonesian_date_formatter.dart';
import '../../../model/task.dart';
import '../components/neu_button.dart';
import '../components/neu_surface.dart';
import '../home/widgets/delete_task_dialog.dart';
import 'widgets/history_date_card.dart';
import 'widgets/history_group_section.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key, required this.onOpenTaskSheet});

  final Future<void> Function({Task? task}) onOpenTaskSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);
    final now = ref.watch(clockProvider).now();
    final groups = _groupTasksByCreatedAt(state.tasks);

    Future<void> pickDateRange() async {
      final initialRange = _resolveInitialRange(now, state.startDate, state.endDate);
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 10, 1, 1),
        lastDate: DateTime(now.year + 10, 12, 31),
        initialDateRange: initialRange,
      );
      if (picked == null) {
        return;
      }
      await controller.setDateRange(start: picked.start, end: picked.end);
    }

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 420 ? 420.0 : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: UIPalette.base,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: UIPalette.raisedMedium(),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            HistoryDateCard(date: now),
                            const SizedBox(width: 12),
                            Expanded(
                              child: NeuSurface(
                                pressed: true,
                                radius: 16,
                                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'Filter tanggal',
                                      style: UITypography.sectionLabel,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _filterSummary(state.startDate, state.endDate),
                                      style: UITypography.captionStrong,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: NeuButton(
                                            key: const Key('history-date-range-button'),
                                            radius: 10,
                                            height: 34,
                                            onTap: pickDateRange,
                                            child: const Text('Pilih rentang'),
                                          ),
                                        ),
                                        if (state.hasDateFilter) ...<Widget>[
                                          const SizedBox(width: 8),
                                          NeuButton(
                                            key: const Key('history-clear-filter-button'),
                                            radius: 10,
                                            height: 34,
                                            onTap: controller.clearDateRange,
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Riwayat tugas', style: UITypography.sectionLabel),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (state.isLoading)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(color: UIPalette.accent),
                            ),
                          )
                        else if (state.tasks.isEmpty)
                          Expanded(
                            child: NeuSurface(
                              key: const Key('history-empty-state'),
                              pressed: true,
                              radius: 18,
                              child: Center(
                                child: Text(
                                  state.hasDateFilter
                                      ? 'Tidak ada riwayat pada rentang ini.'
                                      : 'Belum ada riwayat tugas.',
                                  style: UITypography.captionStrong,
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              key: const Key('history-list'),
                              itemCount: groups.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final group = groups[index];
                                return HistoryGroupSection(
                                  createdDate: group.createdDate,
                                  tasks: group.tasks,
                                  onOpen: (task) async {
                                    await onOpenTaskSheet(task: task);
                                  },
                                  onUndo: controller.undoDone,
                                  onEdit: (task) async {
                                    await onOpenTaskSheet(task: task);
                                  },
                                  onDelete: (task) async {
                                    final shouldDelete = await showDialog<bool>(
                                      context: context,
                                      barrierColor: Colors.black.withValues(alpha: 0.25),
                                      builder: (_) => DeleteTaskDialog(taskTitle: task.title),
                                    );
                                    if (shouldDelete == true) {
                                      await controller.deleteTask(task.id);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        if (state.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              state.errorMessage!,
                              style: UITypography.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  DateTimeRange _resolveInitialRange(
    DateTime now,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    if (startDate != null && endDate != null) {
      return DateTimeRange(
        start: DateTime(startDate.year, startDate.month, startDate.day),
        end: DateTime(endDate.year, endDate.month, endDate.day),
      );
    }

    final normalizedNow = DateTime(now.year, now.month, now.day);
    return DateTimeRange(
      start: normalizedNow.subtract(const Duration(days: 6)),
      end: normalizedNow,
    );
  }

  String _filterSummary(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Semua riwayat 14 hari terakhir';
    }
    return '${IndonesianDateFormatter.fullDate(startDate)} - ${IndonesianDateFormatter.fullDate(endDate)}';
  }

  List<_HistoryGroup> _groupTasksByCreatedAt(List<Task> tasks) {
    final grouped = <DateTime, List<Task>>{};

    for (final task in tasks) {
      final createdAt = task.createdAt;
      final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
      grouped.putIfAbsent(day, () => <Task>[]).add(task);
    }

    final groups = grouped.entries
        .map((entry) => _HistoryGroup(createdDate: entry.key, tasks: entry.value))
        .toList()
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return groups;
  }
}

class _HistoryGroup {
  const _HistoryGroup({
    required this.createdDate,
    required this.tasks,
  });

  final DateTime createdDate;
  final List<Task> tasks;
}
