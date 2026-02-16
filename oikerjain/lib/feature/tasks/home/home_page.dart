import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/constants/ui_palette.dart';
import '../../../core/constants/ui_typography.dart';
import '../../../model/task.dart';
import '../components/neu_button.dart';
import '../components/neu_surface.dart';
import '../edit/edit_page.dart';
import 'home_state.dart';
import 'widgets/dashboard_control_unit.dart';
import 'widgets/date_module.dart';
import 'widgets/delete_task_dialog.dart';
import 'widgets/pulse_dot.dart';
import 'widgets/smooth_schedule_transition.dart';
import 'widgets/swipe_background.dart';
import 'widgets/task_cartridge.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final now = ref.watch(clockProvider).now();
    final visibleTasks = state.visibleTasks(
      nowEpochMillis: now.millisecondsSinceEpoch,
    );
    final scheduleSignature = visibleTasks
        .map(
          (task) =>
              '${task.id}:${task.dueAtEpochMillis}:${task.updatedAtEpochMillis}:${task.isDone ? 1 : 0}',
        )
        .join('|');
    final criticalTask = state.criticalTask();

    Future<void> openTaskSheet({Task? task}) async {
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
        await controller.refresh();
      }
    }

    return Scaffold(
      backgroundColor: UIPalette.base,
      body: SafeArea(
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
                                              onChanged:
                                                  controller.setSearchQuery,
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                hintText: 'Cari tugas...',
                                                hintStyle:
                                                    UITypography.inputHint,
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
                                  children: TaskCategoryFilter.values.map((
                                    filter,
                                  ) {
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
                                    else if (visibleTasks.isEmpty)
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
                                          child: ListView.separated(
                                            itemCount: visibleTasks.length,
                                            separatorBuilder: (_, _) =>
                                                const SizedBox(height: 12),
                                            itemBuilder: (context, index) {
                                              final task = visibleTasks[index];
                                              return Dismissible(
                                                key: Key(
                                                  'task-dismiss-${task.id}',
                                                ),
                                                direction:
                                                    DismissDirection.horizontal,
                                                confirmDismiss:
                                                    (direction) async {
                                                      if (direction ==
                                                          DismissDirection
                                                              .startToEnd) {
                                                        await openTaskSheet(
                                                          task: task,
                                                        );
                                                        return false;
                                                      }

                                                      final shouldDelete =
                                                          await showDialog<bool>(
                                                        context: context,
                                                        barrierColor: Colors.black
                                                            .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                        builder: (_) {
                                                          return DeleteTaskDialog(
                                                            taskTitle: task.title,
                                                          );
                                                        },
                                                      );

                                                      if (shouldDelete == true) {
                                                        await controller.deleteTask(
                                                          task.id,
                                                        );
                                                      }
                                                      return false;
                                                    },
                                                background: const SwipeBackground(
                                                  icon: Icons.edit_rounded,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  color: Colors.blueGrey,
                                                  label: 'Ubah',
                                                ),
                                                secondaryBackground:
                                                    const SwipeBackground(
                                                  icon: Icons.delete_rounded,
                                                  alignment:
                                                      Alignment.centerRight,
                                                  color: Colors.redAccent,
                                                  label: 'Hapus',
                                                ),
                                                child: TaskCartridge(
                                                  task: task,
                                                  isOverdue: controller
                                                      .isOverdue(task),
                                                  onToggle: () => controller
                                                      .toggleStatus(task.id),
                                                ),
                                              );
                                            },
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
                              onTap: () => openTaskSheet(),
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
      ),
    );
  }
}
