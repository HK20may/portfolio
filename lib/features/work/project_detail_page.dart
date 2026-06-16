import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/portfolio_data.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/launch.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/grain_overlay.dart';
import '../../shared/widgets/magnetic_button.dart';
import '../../shared/widgets/pills.dart';
import '../../shared/cursor/cursor_scope.dart';
import '../home/sections/work_section.dart' show ProjectVisual;
import 'project_demos.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key, required this.id});
  final String id;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = PortfolioData.projectById(id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: AuroraBackground()),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.pageGutter,
                context.responsive<double>(mobile: 90, desktop: 120),
                context.pageGutter,
                Insets.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: project == null
                      ? _NotFound(onBack: () => _back(context))
                      : _Detail(project: project, onBack: () => _back(context)),
                ),
              ),
            ),
          ),
          const Positioned.fill(child: GrainOverlay()),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.project, required this.onBack});
  final dynamic project;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final titleSize =
        context.responsive<double>(mobile: 38, tablet: 52, desktop: 64);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Back ────────────────────────────────────────────────────────────
        _BackButton(onTap: onBack),
        const SizedBox(height: Insets.xl),

        // ── Context / Title / Subtitle ───────────────────────────────────
        Text(
          project.context as String,
          style: AppText.mono(size: 13, color: project.accent as Color),
        ),
        const SizedBox(height: Insets.md),
        Text(
          project.title as String,
          style: AppText.display(
            size: titleSize,
            weight: FontWeight.w800,
            height: 1.02,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Text(
          project.subtitle as String,
          style: AppText.body(
            size: context.responsive<double>(mobile: 17, desktop: 20),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: Insets.xl),

        // ── Slim Hero accent band (preserves Hero tag for card→detail flight)
        Hero(
          tag: 'project-${project.id}',
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  (project.accent as Color).withOpacity(0.32),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(Corners.lg),
            ),
            padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
            child: Row(
              children: [
                if (project.metric != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(Corners.pill),
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Text(
                      project.metric as String,
                      style: AppText.mono(
                          size: 12, color: AppColors.textPrimary, spacing: 0.5),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  project.year as String,
                  style: AppText.mono(
                      size: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Insets.xxl),

        // ── About ────────────────────────────────────────────────────────
        Text('About',
            style: AppText.display(size: 22, weight: FontWeight.w700)),
        const SizedBox(height: Insets.lg),
        Text(
          project.description as String,
          style: AppText.body(
            size: context.responsive<double>(mobile: 16, desktop: 18),
            color: AppColors.textSecondary,
            height: 1.75,
          ),
        ),
        const SizedBox(height: Insets.xxl),

        // ── Live Demo ────────────────────────────────────────────────────
        if (ProjectDemos.has(project.id as String)) ...[
          Text('Live Demo',
              style: AppText.display(size: 22, weight: FontWeight.w700)),
          const SizedBox(height: Insets.lg),
          GlassContainer(
            padding: const EdgeInsets.all(Insets.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: context.responsive<double>(
                    mobile: 500, tablet: 580, desktop: 640),
              ),
              child: ProjectDemos.build(context, project.id as String)!,
            ),
          ),
          const SizedBox(height: Insets.xxl),
        ],

        // ── Highlights ───────────────────────────────────────────────────
        Text('Highlights',
            style: AppText.display(size: 22, weight: FontWeight.w700)),
        const SizedBox(height: Insets.lg),
        for (final h in project.highlights as List<String>)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 14),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: project.accent as Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    h,
                    style: AppText.body(
                      size: 16,
                      color: AppColors.textSecondary,
                      height: 1.65,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: Insets.xl),

        // ── Tags ─────────────────────────────────────────────────────────
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final t in project.tags as List<String>)
              TagPill(t, accent: project.accent as Color),
          ],
        ),
        const SizedBox(height: Insets.xxl),

        // ── CTAs ─────────────────────────────────────────────────────────
        Wrap(
          spacing: Insets.md,
          runSpacing: Insets.md,
          children: [
            if ((project.id as String) == 'stock-prediction')
              MagneticButton(
                label: 'Full simulator →',
                filled: true,
                icon: Icons.science_outlined,
                onPressed: () => context.go('/lab'),
              ),
            if (project.link != null)
              MagneticButton(
                label: 'View on GitHub',
                filled: (project.id as String) != 'stock-prediction',
                icon: Icons.arrow_outward_rounded,
                onPressed: () => openUrl(project.link as String),
              ),
            MagneticButton(
              label: 'Explore the Lab →',
              icon: Icons.science_rounded,
              onPressed: () => context.go('/lab'),
            ),
          ],
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: context.usePointerInteractions
          ? SystemMouseCursors.none
          : SystemMouseCursors.click,
      onEnter: (_) => CursorScope.maybeOf(context)?.setHovering(true),
      onExit: (_) => CursorScope.maybeOf(context)?.setHovering(false),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back_rounded,
                size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Back to work',
              style: AppText.body(
                size: 15,
                weight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(onTap: onBack),
        const SizedBox(height: Insets.xxl),
        Text(
          'Project not found.',
          style: AppText.display(size: 40, weight: FontWeight.w800),
        ),
        const SizedBox(height: Insets.md),
        Text(
          'That case doesn\'t exist — it may have moved.',
          style: AppText.body(size: 17),
        ),
      ],
    );
  }
}
