import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/models.dart';
import '../../../core/data/portfolio_data.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/reveal_on_scroll.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/tilt_card.dart';
import '../../work/project_demos.dart';

class WorkSection extends StatelessWidget {
  const WorkSection({super.key});

  @override
  Widget build(BuildContext context) {
    const projects = PortfolioData.projects;
    final columns = context.responsive(mobile: 1, tablet: 2, desktop: 2);
    const gap = Insets.lg;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.pageGutter,
        vertical: context.responsive(mobile: Insets.xxl, desktop: Insets.xxxl),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.maxContent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RevealOnScroll(
              child: SectionHeader(
                eyebrow: 'the work',
                title: 'Selected work.',
                accent: AppColors.pink,
              ),
            ),
            const SizedBox(height: Insets.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Text(
                'A few products I\'ve shipped — from statewide government '
                'platforms to apps in millions of pockets.',
                style: AppText.body(size: 16, color: AppColors.textSecondary),
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
                    for (var i = 0; i < projects.length; i++)
                      SizedBox(
                        width: cardWidth,
                        child: RevealOnScroll(
                          delay: Duration(milliseconds: 70 * i),
                          child: ProjectCard(project: projects[i]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectCard extends StatefulWidget {
  const ProjectCard({super.key, required this.project});
  final Project project;

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _glow.forward(),
      onExit: (_) => _glow.reverse(),
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, child) {
          final t = MediaQuery.of(context).disableAnimations ? 0.0 : _glow.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Corners.lg),
              boxShadow: [
                BoxShadow(
                  color: widget.project.accent.withOpacity(0.28 * t),
                  blurRadius: 32,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: TiltCard(
          glareColor: widget.project.accent,
          onTap: () => context.go('/work/${widget.project.id}'),
          child: GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ProjectVisual(project: widget.project, height: 168),
                Padding(
                  padding: EdgeInsets.all(
                    context.responsive<double>(mobile: Insets.md, desktop: Insets.xl),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.project.context,
                        style: AppText.mono(
                          size: 12,
                          color: widget.project.accent.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.project.title,
                        style: AppText.display(
                          size: context.responsive<double>(mobile: 22, desktop: 26),
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.project.subtitle,
                        style: AppText.body(
                            size: 15, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: Insets.lg),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in widget.project.tags.take(4))
                            TagPill(tag),
                          if (ProjectDemos.has(widget.project.id))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.project.accent.withOpacity(0.14),
                                borderRadius:
                                    BorderRadius.circular(Corners.pill),
                                border: Border.all(
                                    color:
                                        widget.project.accent.withOpacity(0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_circle_outline_rounded,
                                      size: 12,
                                      color: widget.project.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Live demo',
                                    style: AppText.mono(
                                      size: 10,
                                      color: widget.project.accent,
                                      spacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: Insets.lg),
                      Row(
                        children: [
                          Text(
                            'View case',
                            style: AppText.body(
                              size: 14,
                              weight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The stylized header used on both the card and the detail page (shared via
/// a Hero for a seamless transition). No screenshots needed — an accent-lit
/// motif carries the identity.
class ProjectVisual extends StatelessWidget {
  const ProjectVisual({super.key, required this.project, required this.height});
  final Project project;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'project-${project.id}',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      project.accent.withOpacity(0.40),
                      AppColors.surface.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -10,
                bottom: -28,
                child: Text(
                  project.title.substring(0, 1),
                  style: AppText.display(
                    size: height * 1.1,
                    weight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              if (project.metric != null)
                Positioned(
                  left: Insets.lg,
                  top: Insets.lg,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(Corners.pill),
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Text(
                      project.metric!,
                      style: AppText.mono(
                        size: 12,
                        color: AppColors.textPrimary,
                        spacing: 0.5,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: Insets.lg,
                top: Insets.lg,
                child: Text(
                  project.year,
                  style: AppText.mono(size: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
