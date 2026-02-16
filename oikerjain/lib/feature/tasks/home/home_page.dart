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

enum _HomeTab { active, history }

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  _HomeTab _selectedTab = _HomeTab.active;

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

  Future<void> _selectTab(_HomeTab tab) async {
    if (_selectedTab == tab) {
      return;
    }

    setState(() {
      _selectedTab = tab;
    });

    if (tab == _HomeTab.active) {
      await ref.read(homeControllerProvider.notifier).refresh();
      return;
    }
    await ref.read(historyControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIPalette.base,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) {
          var beginOffset = const Offset(0.03, 0);
          final key = child.key;
          if (key is ValueKey<_HomeTab> && key.value == _HomeTab.active) {
            beginOffset = const Offset(-0.03, 0);
          }

          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: beginOffset,
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<_HomeTab>(_selectedTab),
          child: _selectedTab == _HomeTab.active
              ? _ActiveTasksTab(onOpenTaskSheet: _openTaskSheet)
              : HistoryPage(onOpenTaskSheet: _openTaskSheet),
        ),
      ),
      bottomNavigationBar: _HomeBottomNavigationBar(
        selectedTab: _selectedTab,
        onSelectTab: _selectTab,
        onAddTap: () => _openTaskSheet(),
      ),
    );
  }
}

class _HomeBottomNavigationBar extends StatelessWidget {
  const _HomeBottomNavigationBar({
    required this.selectedTab,
    required this.onSelectTab,
    required this.onAddTap,
  });

  final _HomeTab selectedTab;
  final ValueChanged<_HomeTab> onSelectTab;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    const indicatorWidth = 58.0;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
        child: SizedBox(
          height: 98,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NeuSurface(
                  pressed: true,
                  radius: 26,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final centerGap = (constraints.maxWidth * 0.34)
                          .clamp(84.0, 104.0)
                          .toDouble();
                      final sideWidth =
                          ((constraints.maxWidth - centerGap) / 2)
                              .clamp(0.0, double.infinity)
                              .toDouble();
                      final activeIndex = selectedTab == _HomeTab.active ? 0 : 1;
                      final indicatorCenter = activeIndex == 0
                          ? sideWidth / 2
                          : sideWidth + centerGap + (sideWidth / 2);
                      final indicatorLeft = (indicatorCenter - (indicatorWidth / 2))
                          .clamp(0.0, constraints.maxWidth - indicatorWidth)
                          .toDouble();

                      return SizedBox(
                        height: 56,
                        child: Stack(
                          children: <Widget>[
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              left: indicatorLeft,
                              bottom: 2,
                              child: Container(
                                width: indicatorWidth,
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: UIPalette.accent.withValues(alpha: 0.72),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: UIPalette.accent.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                SizedBox(
                                  width: sideWidth,
                                  child: _BottomNavTab(
                                    key: const Key('nav-active-tab'),
                                    label: 'Aktif',
                                    icon: Icons.task_alt_rounded,
                                    active: selectedTab == _HomeTab.active,
                                    onTap: () => onSelectTab(_HomeTab.active),
                                  ),
                                ),
                                SizedBox(width: centerGap),
                                SizedBox(
                                  width: sideWidth,
                                  child: _BottomNavTab(
                                    key: const Key('nav-history-tab'),
                                    label: 'Riwayat',
                                    icon: Icons.history_rounded,
                                    active: selectedTab == _HomeTab.history,
                                    onTap: () => onSelectTab(_HomeTab.history),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: _BottomNavAddButton(onTap: onAddTap),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      'Tambah',
                      style: UITypography.captionStrong.copyWith(
                        color: UIPalette.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavTab extends StatelessWidget {
  const _BottomNavTab({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? UIPalette.accent : UIPalette.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: UIPalette.accent.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: active
                ? Colors.white.withValues(alpha: 0.34)
                : Colors.transparent,
            boxShadow: active
                ? <BoxShadow>[
                    BoxShadow(
                      color: UIPalette.shadowDark.withValues(alpha: 0.15),
                      offset: const Offset(2, 2),
                      blurRadius: 5,
                    ),
                    BoxShadow(
                      color: UIPalette.shadowLight.withValues(alpha: 0.5),
                      offset: const Offset(-2, -2),
                      blurRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: UITypography.button.copyWith(color: foreground),
            child: IconTheme(
              data: IconThemeData(color: foreground, size: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon),
                  const SizedBox(height: 4),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavAddButton extends StatefulWidget {
  const _BottomNavAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_BottomNavAddButton> createState() => _BottomNavAddButtonState();
}

class _BottomNavAddButtonState extends State<_BottomNavAddButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.93 : 1.0;

    return GestureDetector(
      key: const Key('nav-add-button'),
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: Duration(milliseconds: _pressed ? 100 : 220),
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: UIPalette.base,
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
            boxShadow: <BoxShadow>[
              ...(_pressed ? UIPalette.pressed() : UIPalette.raisedSmall()),
              BoxShadow(
                color: UIPalette.accent.withValues(alpha: _pressed ? 0.24 : 0.38),
                blurRadius: _pressed ? 12 : 20,
                spreadRadius: _pressed ? 0 : 2,
              ),
            ],
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: UIPalette.accent,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: UIPalette.accent.withValues(alpha: _pressed ? 0.24 : 0.45),
                    blurRadius: _pressed ? 8 : 14,
                    spreadRadius: _pressed ? 0 : 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bolt_rounded,
                size: 30,
                color: Colors.white,
              ),
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
                  child: Column(
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
