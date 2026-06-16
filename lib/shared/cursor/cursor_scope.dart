import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';

/// Provides pointer position + hover state to descendants and paints the
/// custom magnetic cursor on pointer devices. Interactive widgets call
/// [CursorScopeState.setHovering] on enter/exit so the ring can react.
class CursorScope extends StatefulWidget {
  const CursorScope({super.key, required this.child});
  final Widget child;

  static CursorScopeState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_CursorInherited>()
        ?.state;
  }

  static CursorScopeState of(BuildContext context) {
    final s = maybeOf(context);
    assert(s != null, 'CursorScope.of() called with no CursorScope above.');
    return s!;
  }

  @override
  CursorScopeState createState() => CursorScopeState();
}

class CursorScopeState extends State<CursorScope> {
  final ValueNotifier<Offset> position = ValueNotifier<Offset>(Offset.zero);
  final ValueNotifier<bool> hovering = ValueNotifier<bool>(false);

  void setHovering(bool value) => hovering.value = value;

  @override
  void dispose() {
    position.dispose();
    hovering.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pointer = context.usePointerInteractions;

    Widget content = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: (e) {
        final p = e.position;
        if (p.dx.isFinite && p.dy.isFinite) position.value = p;
      },
      onPointerMove: (e) {
        final p = e.position;
        if (p.dx.isFinite && p.dy.isFinite) position.value = p;
      },
      child: MouseRegion(
        cursor: pointer ? SystemMouseCursors.none : MouseCursor.defer,
        child: widget.child,
      ),
    );

    return _CursorInherited(
      state: this,
      child: Stack(
        children: [
          content,
          if (pointer)
            Positioned.fill(
              child: IgnorePointer(
                child: _MagneticCursor(position: position, hovering: hovering),
              ),
            ),
        ],
      ),
    );
  }
}

class _CursorInherited extends InheritedWidget {
  const _CursorInherited({required this.state, required super.child});
  final CursorScopeState state;

  @override
  bool updateShouldNotify(_CursorInherited oldWidget) => false;
}

class _MagneticCursor extends StatefulWidget {
  const _MagneticCursor({required this.position, required this.hovering});
  final ValueNotifier<Offset> position;
  final ValueNotifier<bool> hovering;

  @override
  State<_MagneticCursor> createState() => _MagneticCursorState();
}

class _MagneticCursorState extends State<_MagneticCursor>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Offset _current = Offset.zero;
  double _radius = 13;

  @override
  void initState() {
    super.initState();
    _current = widget.position.value;
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration _) {
    final target = widget.position.value;
    // Trailing follow — the ring eases toward the pointer each frame.
    final next = Offset.lerp(_current, target, 0.18)!;
    final targetRadius = widget.hovering.value ? 30.0 : 13.0;
    final nextRadius = _radius + (targetRadius - _radius) * 0.2;
    if ((next - _current).distance > 0.05 ||
        (nextRadius - _radius).abs() > 0.05) {
      setState(() {
        _current = next;
        _radius = nextRadius;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.hovering,
      builder: (context, hovering, _) {
        return CustomPaint(
          painter: _CursorPainter(
            center: _current,
            radius: _radius,
            hovering: hovering,
          ),
        );
      },
    );
  }
}

class _CursorPainter extends CustomPainter {
  _CursorPainter({
    required this.center,
    required this.radius,
    required this.hovering,
  });
  final Offset center;
  final double radius;
  final bool hovering;

  @override
  void paint(Canvas canvas, Size size) {
    if (!center.dx.isFinite || !center.dy.isFinite || !radius.isFinite) return;

    if (hovering) {
      // Soft accent glow when hovering over interactive elements.
      final glow = Paint()
        ..color = AppColors.cyan.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, radius, glow);
      final fill = Paint()..color = AppColors.cyan.withValues(alpha: 0.10);
      canvas.drawCircle(center, radius, fill);
    }

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.cyan.withValues(alpha: hovering ? 0.92 : 0.55);
    canvas.drawCircle(center, radius, ring);

    if (!hovering) {
      final dot = Paint()..color = AppColors.textPrimary.withValues(alpha: 0.9);
      canvas.drawCircle(center, 2.4, dot);
    }
  }

  @override
  bool shouldRepaint(_CursorPainter old) =>
      old.center != center || old.radius != radius || old.hovering != hovering;
}
