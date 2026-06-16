import 'package:flutter/material.dart';

import '../../core/data/models.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/launch.dart';
import '../cursor/cursor_scope.dart';

/// A wrap of text-based social links (no brand-icon dependency — reads cleaner
/// and stays on-brand for an editorial layout).
class SocialRow extends StatelessWidget {
  const SocialRow({
    super.key,
    required this.links,
    this.spacing = Insets.lg,
    this.runSpacing = Insets.md,
    this.fontSize = 16,
  });

  final List<SocialLink> links;
  final double spacing;
  final double runSpacing;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        for (final link in links)
          SocialLinkText(link: link, fontSize: fontSize),
      ],
    );
  }
}

class SocialLinkText extends StatefulWidget {
  const SocialLinkText({super.key, required this.link, this.fontSize = 16});
  final SocialLink link;
  final double fontSize;

  @override
  State<SocialLinkText> createState() => _SocialLinkTextState();
}

class _SocialLinkTextState extends State<SocialLinkText> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final pointer = context.usePointerInteractions;
    return MouseRegion(
      cursor: pointer ? SystemMouseCursors.none : SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hover = true);
        CursorScope.maybeOf(context)?.setHovering(true);
      },
      onExit: (_) {
        setState(() => _hover = false);
        CursorScope.maybeOf(context)?.setHovering(false);
      },
      child: GestureDetector(
        onTap: () => openUrl(widget.link.url),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.link.label,
                  style: AppText.body(
                    size: widget.fontSize,
                    weight: FontWeight.w500,
                    color: _hover ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                AnimatedSlide(
                  duration: Motion.fast,
                  offset: _hover ? const Offset(0.18, -0.18) : Offset.zero,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: widget.fontSize,
                      color: _hover ? AppColors.cyan : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: Motion.fast,
              curve: Curves.easeOutCubic,
              height: 1.5,
              width: _hover ? widget.fontSize * widget.link.label.length * 0.62 : 0,
              decoration: BoxDecoration(
                gradient: AppColors.subtleGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
