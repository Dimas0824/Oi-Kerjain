import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/di.dart';
import '../../../core/constants/ui_palette.dart';
import '../../../core/constants/ui_typography.dart';
import '../../../model/task.dart';
import '../../../model/task_category.dart';
import '../../../model/task_priority.dart';
import '../components/neu_button.dart';
import '../components/neu_surface.dart';
import '../edit/edit_page.dart';
import 'home_state.dart';

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
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                10,
                              ),
                              child: Row(
                                children: <Widget>[
                                  _DateModule(now: now),
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
                              child: _DashboardControlUnit(
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
                                    final active =
                                        state.filterCategory == filter;
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
                                          onTap: () => controller
                                              .setCategoryFilter(filter),
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
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  98,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text(
                                            'Tugas aktif',
                                            style: UITypography.sectionLabel,
                                          ),
                                          _PulseDot(),
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
                                        child: _SmoothScheduleTransition(
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
                                                confirmDismiss: (direction) async {
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
                                                        barrierColor: Colors
                                                            .black
                                                            .withValues(
                                                              alpha: 0.25,
                                                            ),
                                                        builder: (_) {
                                                          return _DeleteTaskDialog(
                                                            taskTitle:
                                                                task.title,
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
                                                background: _SwipeBackground(
                                                  icon: Icons.edit_rounded,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  color: Colors.blueGrey,
                                                  label: 'Ubah',
                                                ),
                                                secondaryBackground:
                                                    _SwipeBackground(
                                                      icon:
                                                          Icons.delete_rounded,
                                                      alignment:
                                                          Alignment.centerRight,
                                                      color: Colors.redAccent,
                                                      label: 'Hapus',
                                                    ),
                                                child: _TaskCartridge(
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

class _DeleteTaskDialog extends StatelessWidget {
  const _DeleteTaskDialog({required this.taskTitle});

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

class _SmoothScheduleTransition extends StatefulWidget {
  const _SmoothScheduleTransition({
    required this.signature,
    required this.child,
  });

  final String signature;
  final Widget child;

  @override
  State<_SmoothScheduleTransition> createState() =>
      _SmoothScheduleTransitionState();
}

class _SmoothScheduleTransitionState extends State<_SmoothScheduleTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.012),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

  @override
  void didUpdateWidget(covariant _SmoothScheduleTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signature != widget.signature) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _DateModule extends StatelessWidget {
  const _DateModule({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SizedBox(
        width: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _weekdayShort(now.weekday),
              style: const TextStyle(
                color: UIPalette.textMuted,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            Text(
              '${now.day} ${_monthShort(now.month)}',
              style: const TextStyle(
                color: UIPalette.textSecondary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'SEN';
      case DateTime.tuesday:
        return 'SEL';
      case DateTime.wednesday:
        return 'RAB';
      case DateTime.thursday:
        return 'KAM';
      case DateTime.friday:
        return 'JUM';
      case DateTime.saturday:
        return 'SAB';
      case DateTime.sunday:
        return 'MIN';
      default:
        return '';
    }
  }

  String _monthShort(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'Mei';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Agu';
      case 9:
        return 'Sep';
      case 10:
        return 'Okt';
      case 11:
        return 'Nov';
      case 12:
        return 'Des';
      default:
        return '';
    }
  }
}

class _DashboardControlUnit extends StatelessWidget {
  const _DashboardControlUnit({
    required this.progress,
    required this.pendingTasks,
    required this.criticalTask,
  });

  final int progress;
  final int pendingTasks;
  final Task? criticalTask;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 460),
                curve: Curves.easeInOutCubic,
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: criticalTask == null ? Colors.teal : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color:
                          (criticalTask == null
                                  ? Colors.teal
                                  : Colors.redAccent)
                              .withValues(alpha: 0.7),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 460),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.025),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  criticalTask == null
                      ? 'Semua aman'
                      : 'Perlu perhatian prioritas',
                  key: ValueKey<bool>(criticalTask == null),
                  style: UITypography.sectionLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _WateryProgressOrb(progress: progress),
              const SizedBox(width: 12),
              Expanded(
                child: NeuSurface(
                  pressed: true,
                  radius: 10,
                  padding: const EdgeInsets.all(10),
                  child: SizedBox(
                    height: 88,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 560),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.008, 0.02),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: criticalTask == null
                          ? const Center(
                              key: ValueKey<String>('no-critical'),
                              child: Text(
                                'Tidak ada tugas prioritas',
                                textAlign: TextAlign.center,
                                style: UITypography.captionStrong,
                              ),
                            )
                          : Column(
                              key: ValueKey<String>(
                                'critical-${criticalTask!.id}-${criticalTask!.updatedAtEpochMillis}',
                              ),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Fokus utama',
                                  style: UITypography.micro,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  criticalTask!.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: UIPalette.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Tenggat: ${DateFormat('dd-MM-yyyy HH:mm').format(criticalTask!.dueAt)}',
                                  style: TextStyle(
                                    color: criticalTask!.priority.rank >= 3
                                        ? Colors.redAccent
                                        : UIPalette.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 460),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.015),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  'Tugas tertunda: $pendingTasks',
                  key: ValueKey<int>(pendingTasks),
                  style: const TextStyle(
                    color: UIPalette.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                children: List<Widget>.generate(3, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 460),
                    curve: Curves.easeInOutCubic,
                    margin: const EdgeInsets.only(left: 2),
                    width: 4,
                    height: 12,
                    decoration: BoxDecoration(
                      color: criticalTask == null
                          ? UIPalette.textMuted.withValues(alpha: 0.5)
                          : Colors.redAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WateryProgressOrb extends StatefulWidget {
  const _WateryProgressOrb({required this.progress});

  final int progress;

  @override
  State<_WateryProgressOrb> createState() => _WateryProgressOrbState();
}

class _WateryProgressOrbState extends State<_WateryProgressOrb>
    with SingleTickerProviderStateMixin {
  static const double _orbSize = 132;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeProgress = widget.progress.clamp(0, 100).toInt();

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 920),
      curve: Curves.easeInOutCubic,
      tween: Tween<double>(end: safeProgress / 100),
      builder: (context, animatedProgress, _) {
        final animatedPercent = (animatedProgress * 100).round();
        return SizedBox(
          width: _orbSize,
          height: _orbSize,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.95),
                      UIPalette.base.withValues(alpha: 0.75),
                    ],
                  ),
                  boxShadow: UIPalette.raisedSmall(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(9),
                child: ClipOval(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      return CustomPaint(
                        size: const Size.square(_orbSize),
                        painter: _WaterFillPainter(
                          progress: animatedProgress,
                          phase: _controller.value * 2 * math.pi,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: UIPalette.base.withValues(alpha: 0.88),
                  boxShadow: UIPalette.pressed(),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$animatedPercent%',
                  style: const TextStyle(
                    fontSize: 24,
                    color: UIPalette.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaterFillPainter extends CustomPainter {
  const _WaterFillPainter({required this.progress, required this.phase});

  final double progress;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final clamped = progress.clamp(0.0, 1.0);
    final waterLine = size.height * (1 - clamped);

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.26)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, basePaint);

    final amplitudePrimary = size.height * 0.042;
    final amplitudeSecondary = size.height * 0.032;

    final primaryPath = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y =
          waterLine +
          math.sin((x / size.width * 2 * math.pi) + phase) * amplitudePrimary;
      primaryPath.lineTo(x, y);
    }
    primaryPath
      ..lineTo(size.width, size.height)
      ..close();

    final secondaryPath = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y =
          waterLine +
          math.sin((x / size.width * 2 * math.pi) - (phase * 1.2)) *
              amplitudeSecondary +
          3;
      secondaryPath.lineTo(x, y);
    }
    secondaryPath
      ..lineTo(size.width, size.height)
      ..close();

    final primaryPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          UIPalette.accent.withValues(alpha: 0.8),
          UIPalette.accent.withValues(alpha: 0.55),
        ],
      ).createShader(rect);

    final secondaryPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Colors.white.withValues(alpha: 0.26),
          UIPalette.accent.withValues(alpha: 0.34),
        ],
      ).createShader(rect);

    canvas.drawPath(primaryPath, primaryPaint);
    canvas.drawPath(secondaryPath, secondaryPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterFillPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.phase != phase;
  }
}

class _TaskCartridge extends StatelessWidget {
  const _TaskCartridge({
    required this.task,
    required this.isOverdue,
    required this.onToggle,
  });

  final Task task;
  final bool isOverdue;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final sideColor = task.category == TaskCategory.work
        ? Colors.blueAccent
        : Colors.orangeAccent;

    return NeuSurface(
      key: Key('task-card-${task.id}'),
      radius: 16,
      onTap: onToggle,
      padding: const EdgeInsets.all(0),
      child: Row(
        children: <Widget>[
          Container(
            width: 6,
            height: 104,
            decoration: BoxDecoration(
              color: sideColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeInOutCubic,
                opacity: task.isDone ? 0.55 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeInOutCubic,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              decoration: task.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationThickness: 2,
                              color: UIPalette.textSecondary,
                            ),
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (task.priority.rank == 3)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (task.description.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        task.description.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: UIPalette.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    NeuSurface(
                      pressed: true,
                      radius: 10,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(task.dueAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: UIPalette.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(task.dueAt),
                            style: const TextStyle(
                              color: UIPalette.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            task.category.label,
                            style: const TextStyle(
                              color: UIPalette.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOverdue)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Lewat tenggat',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 52,
            height: 104,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: UIPalette.textMuted.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Center(
              child: NeuSurface(
                pressed: task.isDone,
                radius: 10,
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(
                            begin: 0.9,
                            end: 1,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: task.isDone
                        ? Icon(
                            Icons.check_rounded,
                            key: Key('task-check-icon-${task.id}'),
                            size: 16,
                            color: Colors.white,
                          )
                        : const SizedBox.shrink(key: ValueKey<String>('empty')),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.icon,
    required this.alignment,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Alignment alignment;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isStart = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: EdgeInsets.only(left: isStart ? 18 : 0, right: isStart ? 0 : 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!isStart)
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          Icon(icon, color: color),
          if (isStart)
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
