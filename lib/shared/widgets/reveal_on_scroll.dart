import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/theme/app_text.dart';

/// Wraps content so it fades and slides in the first time it enters the
/// viewport. Direction and distance are configurable; the animation only ever
/// plays once.
class RevealOnScroll extends StatefulWidget {
  const RevealOnScroll({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 48),
    this.threshold = 0.12,
    this.duration = Motion.slow,
  });

  final Widget child;
  final Duration delay;
  final Offset offset;
  final double threshold;
  final Duration duration;

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Motion.emphasized);
  final Key _key = UniqueKey();
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 1;
      _shown = true;
    }
  }

  void _onVisibility(VisibilityInfo info) {
    if (_shown) return;
    if (info.visibleFraction >= widget.threshold) {
      _shown = true;
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _key,
      onVisibilityChanged: _onVisibility,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) {
          final v = _curve.value;
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(
                widget.offset.dx * (1 - v),
                widget.offset.dy * (1 - v),
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
