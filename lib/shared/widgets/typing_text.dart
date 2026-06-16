import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';

/// Terminal-style typing widget that cycles through [phrases] by typing out
/// each one, holding briefly, then deleting and moving to the next.
///
/// Under [reduceMotion] it shows the first phrase fully with a static caret.
class TypingText extends StatefulWidget {
  const TypingText({
    super.key,
    required this.phrases,
    required this.style,
    this.caretColor = AppColors.violet,
  });

  final List<String> phrases;
  final TextStyle style;
  final Color caretColor;

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText>
    with SingleTickerProviderStateMixin {
  int _phraseIdx = 0;
  int _charCount = 0;
  bool _typing = true;

  Timer? _stepTimer;
  late final AnimationController _caretCtrl;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _caretCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      _charCount = widget.phrases.first.length;
    } else {
      _caretCtrl.repeat(reverse: true);
      _step();
    }
  }

  void _step() {
    _stepTimer?.cancel();
    if (!mounted) return;
    final phrase = widget.phrases[_phraseIdx];

    if (_typing) {
      if (_charCount < phrase.length) {
        _stepTimer = Timer(const Duration(milliseconds: 62), () {
          if (mounted) {
            setState(() => _charCount++);
            _step();
          }
        });
      } else {
        // Hold before deleting
        _stepTimer = Timer(const Duration(milliseconds: 1900), () {
          if (mounted) {
            setState(() => _typing = false);
            _step();
          }
        });
      }
    } else {
      if (_charCount > 0) {
        _stepTimer = Timer(const Duration(milliseconds: 36), () {
          if (mounted) {
            setState(() => _charCount--);
            _step();
          }
        });
      } else {
        setState(() {
          _phraseIdx = (_phraseIdx + 1) % widget.phrases.length;
          _typing = true;
        });
        _stepTimer = Timer(const Duration(milliseconds: 280), () {
          if (mounted) _step();
        });
      }
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _caretCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrase = widget.phrases[_phraseIdx];
    final visible = phrase.substring(0, _charCount.clamp(0, phrase.length));

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(child: Text(visible, style: widget.style)),
        AnimatedBuilder(
          animation: _caretCtrl,
          builder: (_, __) => Opacity(
            opacity: context.reduceMotion
                ? 1.0
                : (_caretCtrl.value > 0.5 ? 1.0 : 0.0),
            child: Text(
              '|',
              style: widget.style.copyWith(color: widget.caretColor),
            ),
          ),
        ),
      ],
    );
  }
}
