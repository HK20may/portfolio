import 'package:flutter/material.dart';

import '../../core/theme/app_text.dart';

/// Animated display text. Each glyph rises out from behind its own clip line
/// with a staggered fade — words stay intact and wrap as whole units.
class KineticText extends StatefulWidget {
  const KineticText(
    this.text, {
    super.key,
    required this.style,
    this.play = true,
    this.startDelay = Duration.zero,
    this.perCharMs = 38,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final bool play;
  final Duration startDelay;
  final int perCharMs;
  final TextAlign textAlign;

  @override
  State<KineticText> createState() => _KineticTextState();
}

class _KineticTextState extends State<KineticText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<String> _words;
  late final int _charCount;

  @override
  void initState() {
    super.initState();
    _words = widget.text.split(' ');
    _charCount = widget.text.replaceAll(' ', '').length;
    final total = (_charCount * widget.perCharMs + 520).clamp(600, 2600);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    // _maybePlay() deferred to didChangeDependencies — MediaQuery unavailable in initState.
  }

  void _maybePlay() {
    if (!widget.play) return;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.value = 1;
      return;
    }
    Future.delayed(widget.startDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.play && _controller.value == 0 && !_controller.isAnimating) {
      _maybePlay();
    }
  }

  @override
  void didUpdateWidget(covariant KineticText old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _maybePlay();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.style.fontSize ?? 48;
    var index = 0;

    final wordWidgets = <Widget>[];
    for (final word in _words) {
      final chars = <Widget>[];
      for (final ch in word.split('')) {
        chars.add(_AnimatedChar(
          controller: _controller,
          order: index,
          total: _charCount,
          fontSize: fontSize,
          child: Text(ch, style: widget.style),
        ));
        index++;
      }
      wordWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: chars));
    }

    return Wrap(
      alignment: switch (widget.textAlign) {
        TextAlign.center => WrapAlignment.center,
        TextAlign.end || TextAlign.right => WrapAlignment.end,
        _ => WrapAlignment.start,
      },
      spacing: fontSize * 0.30,
      runSpacing: fontSize * 0.08,
      children: wordWidgets,
    );
  }
}

class _AnimatedChar extends StatelessWidget {
  const _AnimatedChar({
    required this.controller,
    required this.order,
    required this.total,
    required this.fontSize,
    required this.child,
  });

  final AnimationController controller;
  final int order;
  final int total;
  final double fontSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Overlapping windows so glyphs cascade rather than march.
    const span = 0.55;
    final start = total <= 1 ? 0.0 : (order / total) * (1 - span);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(start, start + span, curve: Motion.emphasized),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final v = anim.value;
        return ClipRect(
          child: Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, (1 - v) * fontSize * 0.95),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
