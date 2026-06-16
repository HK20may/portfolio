import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../cursor/cursor_scope.dart';

/// A card that tilts in 3D toward the pointer with a soft moving glare.
/// Falls back to a static card (with tap support) on touch devices.
class TiltCard extends StatefulWidget {
  const TiltCard({
    super.key,
    required this.child,
    this.onTap,
    this.maxTilt = 0.10,
    this.glareColor = Colors.white,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double maxTilt; // radians at the edges
  final Color glareColor;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  Offset _pointer = const Offset(0.5, 0.5); // normalised 0..1
  bool _hovering = false;

  void _update(Offset local, Size size) {
    setState(() {
      _pointer = Offset(
        (local.dx / size.width).clamp(0.0, 1.0).toDouble(),
        (local.dy / size.height).clamp(0.0, 1.0).toDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pointer = context.usePointerInteractions;

    Widget card = LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return MouseRegion(
          onEnter: (_) {
            setState(() => _hovering = true);
            CursorScope.maybeOf(context)?.setHovering(true);
          },
          onExit: (_) {
            setState(() {
              _hovering = false;
              _pointer = const Offset(0.5, 0.5);
            });
            CursorScope.maybeOf(context)?.setHovering(false);
          },
          onHover: pointer ? (e) => _update(e.localPosition, size) : null,
          child: GestureDetector(
            onTap: widget.onTap,
            child: _build3d(size),
          ),
        );
      },
    );

    return card;
  }

  Widget _build3d(Size size) {
    final pointer = context.usePointerInteractions;
    final targetX = pointer && _hovering
        ? (_pointer.dy - 0.5) * 2 * widget.maxTilt
        : 0.0;
    final targetY = pointer && _hovering
        ? -(_pointer.dx - 0.5) * 2 * widget.maxTilt
        : 0.0;
    final targetLift = _hovering ? 1.0 : 0.0;

    return TweenAnimationBuilder<List<double>>(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      tween: _ListTween([targetX, targetY, targetLift]),
      builder: (context, values, child) {
        final rotX = values[0];
        final rotY = values[1];
        final lift = values[2];
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(rotX)
          ..rotateY(rotY)
          ..scale(1 + 0.02 * lift);

        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: Stack(
            children: [
              child!,
              if (lift > 0.01)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Opacity(
                        opacity: 0.10 * lift,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(
                                (_pointer.dx - 0.5) * 2,
                                (_pointer.dy - 0.5) * 2,
                              ),
                              radius: 0.9,
                              colors: [widget.glareColor, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Tweens a fixed-length list element-wise.
class _ListTween extends Tween<List<double>> {
  _ListTween(List<double> end) : super(begin: end, end: end);

  @override
  List<double> lerp(double t) {
    final b = begin!;
    final e = end!;
    return List<double>.generate(e.length, (i) => b[i] + (e[i] - b[i]) * t);
  }
}
