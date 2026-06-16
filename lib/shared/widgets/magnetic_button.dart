import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../cursor/cursor_scope.dart';

/// A call-to-action that leans toward the cursor (magnetic pull) and lifts on
/// hover. Two looks: [filled] paints the aurora gradient; otherwise it's a
/// glassy outline.
class MagneticButton extends StatefulWidget {
  const MagneticButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final IconData? icon;

  @override
  State<MagneticButton> createState() => _MagneticButtonState();
}

class _MagneticButtonState extends State<MagneticButton> {
  Offset _pull = Offset.zero;
  bool _hovering = false;

  void _onHover(Offset local, Size size) {
    if (!local.dx.isFinite || !local.dy.isFinite ||
        !size.width.isFinite || !size.height.isFinite) return;
    final center = Offset(size.width / 2, size.height / 2);
    final delta = local - center;
    setState(() => _pull = delta * 0.22);
  }

  @override
  Widget build(BuildContext context) {
    final pointer = context.usePointerInteractions;
    final fg = widget.filled ? Colors.white : AppColors.textPrimary;

    final inner = Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: 16),
      decoration: BoxDecoration(
        gradient: widget.filled ? AppColors.auroraGradient : null,
        color: widget.filled ? null : AppColors.glassHigh,
        borderRadius: BorderRadius.circular(Corners.pill),
        border: widget.filled
            ? null
            : Border.all(color: AppColors.borderStrong, width: 1),
        boxShadow: widget.filled && _hovering
            ? [
                BoxShadow(
                  color: AppColors.violet.withOpacity(0.45),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w600,
              color: fg,
              height: 1,
            ),
          ),
          if (widget.icon != null) ...[
            const SizedBox(width: 8),
            Icon(widget.icon, size: 18, color: fg),
          ],
        ],
      ),
    );

    return MouseRegion(
      cursor: pointer ? SystemMouseCursors.none : SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovering = true);
        CursorScope.maybeOf(context)?.setHovering(true);
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
          _pull = Offset.zero;
        });
        CursorScope.maybeOf(context)?.setHovering(false);
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedScale(
              scale: _hovering ? 1.04 : 1.0,
              duration: Motion.fast,
              curve: Curves.easeOutCubic,
              child: TweenAnimationBuilder<Offset>(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                tween: Tween(begin: _pull, end: _pull),
                builder: (context, value, child) => Transform.translate(
                  offset: pointer ? value : Offset.zero,
                  child: Listener(
                    onPointerHover: pointer
                        ? (e) => _onHover(e.localPosition, constraints.biggest)
                        : null,
                    child: child,
                  ),
                ),
                child: inner,
              ),
            );
          },
        ),
      ),
    );
  }
}
