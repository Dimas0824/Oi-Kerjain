import 'package:flutter/material.dart';

class SmoothScheduleTransition extends StatefulWidget {
  const SmoothScheduleTransition({
    super.key,
    required this.signature,
    required this.child,
  });

  final String signature;
  final Widget child;

  @override
  State<SmoothScheduleTransition> createState() =>
      _SmoothScheduleTransitionState();
}

class _SmoothScheduleTransitionState extends State<SmoothScheduleTransition>
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
  void didUpdateWidget(covariant SmoothScheduleTransition oldWidget) {
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
