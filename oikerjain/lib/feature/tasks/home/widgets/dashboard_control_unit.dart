import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/ui_palette.dart';
import '../../../../core/constants/ui_typography.dart';
import '../../../../model/task.dart';
import '../../../../model/task_priority.dart';
import '../../components/neu_surface.dart';

class DashboardControlUnit extends StatelessWidget {
  const DashboardControlUnit({
    super.key,
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
