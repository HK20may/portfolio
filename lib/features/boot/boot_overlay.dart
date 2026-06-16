import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// First-load curtain: the monogram settles in while a hairline fills, then the
/// whole panel wipes upward to reveal the hero. Calls [onComplete] when done.
class BootOverlay extends StatefulWidget {
  const BootOverlay({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<BootOverlay> createState() => _BootOverlayState();
}

class _BootOverlayState extends State<BootOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  late final Animation<double> _fill = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.05, 0.62, curve: Curves.easeInOut),
  );
  late final Animation<double> _logo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );
  late final Animation<double> _wipe = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.72, 1.0, curve: Curves.easeInOutCubic),
  );

  bool _reducedHandled = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onComplete();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reducedHandled) return;
    _reducedHandled = true;
    if (context.reduceMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = context.screenHeight;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -_wipe.value * height),
          child: Container(
            color: AppColors.background,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: _logo.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _logo.value) * 16),
                    child: ShaderMask(
                      shaderCallback: (r) =>
                          AppColors.auroraGradient.createShader(r),
                      child: Text(
                        'HK',
                        style: AppText.display(
                          size: 84,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Insets.lg),
                SizedBox(
                  width: 180,
                  child: Stack(
                    children: [
                      Container(height: 2, color: AppColors.border),
                      FractionallySizedBox(
                        widthFactor: _fill.value,
                        child: Container(
                          height: 2,
                          decoration: const BoxDecoration(
                            gradient: AppColors.subtleGradient,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.md),
                Opacity(
                  opacity: _logo.value,
                  child: Text(
                    'harshit kumawat',
                    style: AppText.mono(size: 12, spacing: 3),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
