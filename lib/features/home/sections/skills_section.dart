import 'package:flutter/material.dart';

import '../../../core/data/models.dart';
import '../../../core/data/portfolio_data.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/reveal_on_scroll.dart';
import '../../../shared/widgets/section_header.dart';

class SkillsSection extends StatelessWidget {
  const SkillsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const groups = PortfolioData.skillGroups;
    final columns = context.responsive(mobile: 1, tablet: 2, desktop: 2);
    const gap = Insets.lg;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.pageGutter,
            vertical:
                context.responsive(mobile: Insets.xxl, desktop: Insets.xxxl),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RevealOnScroll(
                  child: SectionHeader(
                    eyebrow: 'skills',
                    title: 'The toolkit.',
                    accent: AppColors.cyan,
                  ),
                ),
                const SizedBox(height: Insets.xxl),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var i = 0; i < groups.length; i++)
                          SizedBox(
                            width: cardWidth,
                            child: RevealOnScroll(
                              delay: Duration(milliseconds: 80 * i),
                              child: _SkillCard(group: groups[i]),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const _TechMarquee(items: PortfolioData.marquee),
        SizedBox(
          height: context.responsive(mobile: Insets.xl, desktop: Insets.xxl),
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.group});
  final SkillGroup group;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(Insets.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            group.title,
            style: AppText.display(size: 22, weight: FontWeight.w700),
          ),
          const SizedBox(height: Insets.lg),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final item in group.items) TagPill(item)],
          ),
        ],
      ),
    );
  }
}

/// Seamless infinite marquee: two identical copies translated by exactly one
/// set width per loop, so the wrap is invisible.
class _TechMarquee extends StatefulWidget {
  const _TechMarquee({required this.items});
  final List<String> items;

  @override
  State<_TechMarquee> createState() => _TechMarqueeState();
}

class _TechMarqueeState extends State<_TechMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 32));
  final GlobalKey _setKey = GlobalKey();
  double? _setWidth;
  double? _setHeight;
  static const double _gap = Insets.xl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = _setKey.currentContext?.size;
      if (size != null && mounted) {
        setState(() {
          _setWidth = size.width;
          _setHeight = size.height;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!context.reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _item(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: _gap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 12),
            decoration: const BoxDecoration(
              gradient: AppColors.subtleGradient,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            label,
            style: AppText.display(
              size: 22,
              weight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget set(Key? key) => Row(
          key: key,
          mainAxisSize: MainAxisSize.min,
          children: [for (final i in widget.items) _item(i)],
        );

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: Insets.lg),
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.10, 0.90, 1.0],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: ClipRect(
          child: SizedBox(
            height: _setHeight ?? 28.0,
            child: OverflowBox(
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final span = _setWidth ?? 0;
                  final dx =
                      _setWidth == null ? 0.0 : -_controller.value * span;
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [set(_setKey), set(null), set(null)],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
