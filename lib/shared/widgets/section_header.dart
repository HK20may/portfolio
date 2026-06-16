import 'dart:math';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Eyebrow + title pairing used to open every section. The eyebrow is styled
/// like a source comment — a small nod to the subject (a developer's site)
/// rather than a generic numbered marker.
///
/// Animates the gradient rule (width 0→26) and eyebrow (fade in) when the
/// header first enters the viewport. Coordinates with the RevealOnScroll
/// wrapper that most sections use — the rule/eyebrow are unique animations
/// that complement rather than duplicate the outer fade-from-below.
class SectionHeader extends StatefulWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.accent = AppColors.cyan,
  });

  final String eyebrow;
  final String title;
  final Color accent;

  @override
  State<SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<SectionHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  final Key _visKey = UniqueKey();
  bool _revealed = false;

  late List<String> _titleChars;
  static const _scramblePool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%&*';
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _titleChars = widget.title.split('');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion && !_revealed) {
      _ctrl.value = 1;
      _revealed = true;
    }
  }

  @override
  void didUpdateWidget(SectionHeader old) {
    super.didUpdateWidget(old);
    if (old.title != widget.title) _titleChars = widget.title.split('');
  }

  void _startScramble() {
    if (!mounted || context.reduceMotion) return;
    final title = widget.title;
    // Seed with scrambled characters
    setState(() {
      _titleChars = title.split('').map((c) {
        if (c == ' ') return ' ';
        return _scramblePool[_rng.nextInt(_scramblePool.length)];
      }).toList();
    });
    // Staggered resolution: each char cycles 4 times then locks
    for (var i = 0; i < title.length; i++) {
      if (title[i] == ' ') continue;
      for (var frame = 0; frame < 5; frame++) {
        final fi = frame;
        final ci = i;
        Future.delayed(Duration(milliseconds: ci * 28 + fi * 38), () {
          if (!mounted) return;
          setState(() {
            _titleChars[ci] = fi >= 4
                ? title[ci]
                : _scramblePool[_rng.nextInt(_scramblePool.length)];
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleSize = context.responsive<double>(
      mobile: 34,
      tablet: 44,
      desktop: 56,
    );

    return VisibilityDetector(
      key: _visKey,
      onVisibilityChanged: (info) {
        if (!_revealed && info.visibleFraction >= 0.3) {
          _revealed = true;
          _ctrl.forward();
          _startScramble();
        }
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final v = Curves.easeOutCubic.transform(_ctrl.value);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gradient rule draws in from width 0.
                  Container(
                    width: 26 * v,
                    height: 2,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.subtleGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Eyebrow fades in alongside the rule.
                  Opacity(
                    opacity: v,
                    child: Text(
                      '// ${widget.eyebrow}',
                      style: AppText.mono(
                        size: 13,
                        color: widget.accent.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Insets.md),
              Text(
                _titleChars.join(),
                style: AppText.display(
                  size: titleSize,
                  weight: FontWeight.w800,
                  height: 1.04,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
