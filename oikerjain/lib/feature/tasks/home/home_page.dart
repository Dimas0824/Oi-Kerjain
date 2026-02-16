import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/constants/ui_palette.dart';
import '../../../core/constants/ui_typography.dart';
import '../../../model/task.dart';
import '../components/neu_button.dart';
import '../components/neu_surface.dart';
import '../edit/edit_page.dart';
import '../history/history_page.dart';
import 'home_state.dart';
import 'widgets/dashboard_control_unit.dart';
import 'widgets/date_module.dart';
import 'widgets/delete_task_dialog.dart';
import 'widgets/pulse_dot.dart';
import 'widgets/smooth_schedule_transition.dart';
import 'widgets/swipe_background.dart';
import 'widgets/task_cartridge.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedTabIndex = 0;

  Future<void> _openTaskSheet({Task? task}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.easeOutCubic,
        duration: Duration(milliseconds: 460),
        reverseCurve: Curves.easeInCubic,
        reverseDuration: Duration(milliseconds: 340),
      ),
      builder: (_) => EditPage(task: task),
    );

    if (changed == true) {
      await ref.read(homeControllerProvider.notifier).refresh();
      await ref.read(historyControllerProvider.notifier).refresh();
    }
  }

  void _selectTab(int index) async {
    if (_selectedTabIndex == index) {
      return;
    }

    setState(() {
      _selectedTabIndex = index;
    });

    if (index == 0) {
      await ref.read(homeControllerProvider.notifier).refresh();
      return;
    }
    await ref.read(historyControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIPalette.base,
      body: IndexedStack(
        index: _selectedTabIndex,
        children: <Widget>[
          _ActiveTasksTab(onOpenTaskSheet: _openTaskSheet),
          HistoryPage(onOpenTaskSheet: _openTaskSheet),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: NeuSurface(
            pressed: true,
            radius: 18,
            padding: const EdgeInsets.all(6),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: NeuButton(
                    key: const Key('nav-active-tab'),
                    active: _selectedTabIndex == 0,
                    radius: 12,
                    height: 40,
                    onTap: () => _selectTab(0),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.task_alt_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Aktif'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NeuButton(
                    key: const Key('nav-history-tab'),
                    active: _selectedTabIndex == 1,
                    radius: 12,
                    height: 40,
                    onTap: () => _selectTab(1),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.history_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Riwayat'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveTasksTab extends ConsumerWidget {
  const _ActiveTasksTab({required this.onOpenTaskSheet});

  final Future<void> Function({Task? task}) onOpenTaskSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final now = ref.watch(clockProvider).now();
    final pendingTasks = state.visibleTasks();
    final completedTodayTasks = state.visibleCompletedTodayTasks();
    final hasVisibleTasks =
        pendingTasks.isNotEmpty || completedTodayTasks.isNotEmpty;
    final scheduleSignature = <Task>[...pendingTasks, ...completedTodayTasks]
        .map(
          (task) =>
              '${task.id}:${task.dueAtEpochMillis}:${task.updatedAtEpochMillis}:${task.completedAtEpochMillis ?? 0}:${task.isDone ? 1 : 0}',
        )
        .join('|');
    final criticalTask = state.criticalTask();

    Widget buildTaskItem(Task task) {
      return Dismissible(
        key: Key('task-dismiss-${task.id}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await onOpenTaskSheet(task: task);
            return false;
          }

          final shouldDelete = await showDialog<bool>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.25),
            builder: (_) {
              return DeleteTaskDialog(taskTitle: task.title);
            },
          );

          if (shouldDelete == true) {
            await controller.deleteTask(task.id);
          }
          return false;
        },
        background: const SwipeBackground(
          icon: Icons.edit_rounded,
          alignment: Alignment.centerLeft,
          color: Colors.blueGrey,
          label: 'Ubah',
        ),
        secondaryBackground: const SwipeBackground(
          icon: Icons.delete_rounded,
          alignment: Alignment.centerRight,
          color: Colors.redAccent,
          label: 'Hapus',
        ),
        child: TaskCartridge(
          task: task,
          isOverdue: controller.isOverdue(task),
          onToggle: () => controller.toggleStatus(task.id),
        ),
      );
    }

    final taskListChildren = <Widget>[
      for (var i = 0; i < pendingTasks.length; i++) ...<Widget>[
        if (i > 0) const SizedBox(height: 12),
        buildTaskItem(pendingTasks[i]),
      ],
      if (completedTodayTasks.isNotEmpty) ...<Widget>[
        if (pendingTasks.isNotEmpty) const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Selesai hari ini',
            key: Key('completed-today-section'),
            style: UITypography.sectionLabel,
          ),
        ),
        for (var i = 0; i < completedTodayTasks.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 12),
          buildTaskItem(completedTodayTasks[i]),
        ],
      ],
    ];

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 420
              ? 420.0
              : constraints.maxWidth;

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
                  child: Stack(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                            child: Row(
                              children: <Widget>[
                                DateModule(now: now),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: NeuSurface(
                                    pressed: true,
                                    radius: 16,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.search_rounded,
                                          color: UIPalette.textMuted,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            key: const Key('search-input'),
                                            onChanged: controller.setSearchQuery,
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              hintText: 'Cari tugas...',
                                              hintStyle: UITypography.inputHint,
                                            ),
                                            style: UITypography.input,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: DashboardControlUnit(
                              progress: state.progress,
                              pendingTasks: state.pendingTasks,
                              criticalTask: criticalTask,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: NeuSurface(
                              pressed: true,
                              radius: 16,
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: TaskCategoryFilter.values.map((filter) {
                                  final active = state.filterCategory == filter;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: NeuButton(
                                        key: Key('filter-${filter.name}'),
                                        active: active,
                                        radius: 12,
                                        height: 38,
                                        onTap: () =>
                                            controller.setCategoryFilter(filter),
                                        child: Text(filter.label),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 98),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          'Tugas aktif',
                                          style: UITypography.sectionLabel,
                                        ),
                                        PulseDot(),
                                      ],
                                    ),
                                  ),
                                  if (state.isLoading)
                                    const Expanded(
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: UIPalette.accent,
                                        ),
                                      ),
                                    )
                                  else if (!hasVisibleTasks)
                                    Expanded(
                                      child: NeuSurface(
                                        pressed: true,
                                        radius: 18,
                                        child: const Center(
                                          child: Text(
                                            'Belum ada tugas yang cocok.',
                                            style: UITypography.captionStrong,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: SmoothScheduleTransition(
                                        signature: scheduleSignature,
                                        child: ListView(
                                          key: const Key('active-task-list'),
                                          children: taskListChildren,
                                        ),
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
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  UIPalette.base.withValues(alpha: 0),
                                  UIPalette.base.withValues(alpha: 0.95),
                                  UIPalette.base,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: NeuButton(
                            key: const Key('fab-add-task'),
                            onTap: () => onOpenTaskSheet(),
                            active: true,
                            width: 68,
                            height: 68,
                            radius: 18,
                            child: const Icon(Icons.bolt_rounded, size: 28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
