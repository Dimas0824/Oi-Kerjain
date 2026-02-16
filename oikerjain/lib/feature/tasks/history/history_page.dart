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
import 'widgets/history_custom_range_sheet.dart';
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

    Future<void> openCustomRangeSheet() async {
      final firstDate = DateTime(now.year - 10, 1, 1);
      final lastDate = DateTime(now.year + 10, 12, 31);
      final initialStart = state.isCustomActive
          ? state.customStartDate!
          : state.weekStartDate;
      final initialEnd = state.isCustomActive
          ? state.customEndDate!
          : state.weekEndDate;
      final clampedStart = _clampDate(
        initialStart,
        firstDate: firstDate,
        lastDate: lastDate,
      );
      final clampedEnd = _clampDate(
        initialEnd,
        firstDate: firstDate,
        lastDate: lastDate,
      );

      final result = await showModalBottomSheet<HistoryRangeSheetResult>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => HistoryCustomRangeSheet(
          initialStartDate: clampedStart,
          initialEndDate: clampedEnd,
          firstDate: firstDate,
          lastDate: lastDate,
        ),
      );
      if (result == null) {
        return;
      }

      if (result.action == HistoryRangeSheetAction.reset) {
        await controller.resetToCurrentWeek();
        return;
      }

      final start = result.startDate;
      final end = result.endDate;
      if (start == null || end == null) {
        return;
      }

      await controller.setDateRange(start: start, end: end);
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
                        NeuSurface(
                          key: const Key('history-week-filter-card'),
                          pressed: true,
                          radius: 16,
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Text(
                                    'Senin - Minggu',
                                    style: UITypography.sectionLabel,
                                  ),
                                  const Spacer(),
                                  if (state.isCustomActive)
                                    Text(
                                      'Custom aktif',
                                      style: UITypography.micro.copyWith(
                                        color: UIPalette.accent,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _compactDateRange(
                                  state.weekStartDate,
                                  state.weekEndDate,
                                ),
                                style: UITypography.bodyStrong,
                              ),
                              if (state.isCustomActive) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  'Range custom: ${_compactDateRange(state.customStartDate!, state.customEndDate!)}',
                                  style: UITypography.captionStrong,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 44,
                                    child: NeuButton(
                                      key: const Key('history-week-prev-button'),
                                      radius: 10,
                                      height: 34,
                                      onTap: () {
                                        controller.showPreviousWeek();
                                      },
                                      child: const Icon(
                                        Icons.chevron_left_rounded,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: NeuButton(
                                      key: const Key('history-custom-range-button'),
                                      radius: 10,
                                      height: 34,
                                      active: state.isCustomActive,
                                      onTap: openCustomRangeSheet,
                                      child: Text(
                                        state.isCustomActive
                                            ? 'Ubah custom'
                                            : 'Pilih custom',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 44,
                                    child: NeuButton(
                                      key: const Key('history-week-next-button'),
                                      radius: 10,
                                      height: 34,
                                      onTap: () {
                                        controller.showNextWeek();
                                      },
                                      child: const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                                  state.isCustomActive
                                      ? 'Tidak ada riwayat pada rentang ini.'
                                      : 'Tidak ada riwayat pada minggu ini.',
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

  String _compactDateRange(DateTime startDate, DateTime endDate) {
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    if (normalizedStart.year == normalizedEnd.year &&
        normalizedStart.month == normalizedEnd.month) {
      return '${normalizedStart.day}-${normalizedEnd.day} ${_monthShortName(normalizedStart.month)} ${normalizedStart.year}';
    }

    if (normalizedStart.year == normalizedEnd.year) {
      return '${normalizedStart.day} ${_monthShortName(normalizedStart.month)} - '
          '${normalizedEnd.day} ${_monthShortName(normalizedEnd.month)} ${normalizedStart.year}';
    }

    return '${normalizedStart.day} ${_monthShortName(normalizedStart.month)} ${normalizedStart.year} - '
        '${normalizedEnd.day} ${_monthShortName(normalizedEnd.month)} ${normalizedEnd.year}';
  }

  String _monthShortName(int month) {
    final fullName = IndonesianDateFormatter.monthName(month);
    if (fullName.isEmpty || fullName.length <= 3) {
      return fullName;
    }
    return fullName.substring(0, 3);
  }

  DateTime _clampDate(
    DateTime value, {
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final normalized = DateTime(value.year, value.month, value.day);
    final start = DateTime(firstDate.year, firstDate.month, firstDate.day);
    final end = DateTime(lastDate.year, lastDate.month, lastDate.day);

    if (normalized.isBefore(start)) {
      return start;
    }
    if (normalized.isAfter(end)) {
      return end;
    }
    return normalized;
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
