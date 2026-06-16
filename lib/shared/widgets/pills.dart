import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Small glassy tag used for tech stacks.
class TagPill extends StatelessWidget {
  const TagPill(this.label, {super.key, this.accent});
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(Corners.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppText.mono(size: 12, color: c, spacing: 0.4),
      ),
    );
  }
}

/// A headline stat — big gradient number over a muted label. The number
/// counts up from 0 to its target when it first scrolls into view.
class StatBlock extends StatefulWidget {
  const StatBlock({
    super.key,
    required this.value,
    required this.label,
    this.size = 40,
  });
  final String value;
  final String label;
  final double size;

  @override
  State<StatBlock> createState() => _StatBlockState();
}

class _StatBlockState extends State<StatBlock> {
  final Key _visKey = UniqueKey();
  bool _triggered = false;

  // Splits "4+" → (4, "+"),  "1M+" → (1, "M+"),  "3" → (3, "")
  ({int number, String suffix}) _parse(String value) {
    final m = RegExp(r'^(\d+)(.*)$').firstMatch(value);
    if (m == null) return (number: 0, suffix: value);
    return (number: int.parse(m.group(1)!), suffix: m.group(2) ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parse(widget.value);

    return VisibilityDetector(
      key: _visKey,
      onVisibilityChanged: (info) {
        if (!_triggered && info.visibleFraction >= 0.5) {
          setState(() => _triggered = true);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: _triggered ? parsed.number.toDouble() : 0,
            ),
            duration: context.reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ShaderMask(
                shaderCallback: (r) => AppColors.subtleGradient.createShader(r),
                child: Text(
                  '${value.round()}${parsed.suffix}',
                  style: AppText.display(
                    size: widget.size,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: AppText.body(size: 13, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
