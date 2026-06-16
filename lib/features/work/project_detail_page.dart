import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/portfolio_data.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/launch.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/grain_overlay.dart';
import '../../shared/widgets/magnetic_button.dart';
import '../../shared/widgets/pills.dart';
import '../../shared/cursor/cursor_scope.dart';
import '../home/sections/work_section.dart' show ProjectVisual;

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
  final dynamic project; // Project
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(onTap: onBack),
        const SizedBox(height: Insets.xl),
        Text(
          project.context,
          style: AppText.mono(size: 13, color: project.accent),
        ),
        const SizedBox(height: Insets.md),
        Text(
          project.title,
          style: AppText.display(
            size: context.responsive<double>(mobile: 40, tablet: 56, desktop: 68),
            weight: FontWeight.w800,
            height: 1.02,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Text(
          project.subtitle,
          style: AppText.body(
            size: context.responsive<double>(mobile: 17, desktop: 20),
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: Insets.xl),
        ClipRRect(
          borderRadius: BorderRadius.circular(Corners.lg),
          child: ProjectVisual(
            project: project,
            height: context.responsive<double>(mobile: 200, desktop: 320),
          ),
        ),
        const SizedBox(height: Insets.xxl),
        Text(
          project.description,
          style: AppText.body(
            size: context.responsive<double>(mobile: 16, desktop: 18),
            color: AppColors.textSecondary,
            height: 1.7,
          ),
        ),
        const SizedBox(height: Insets.xxl),
        Text(
          'Highlights',
          style: AppText.display(size: 22, weight: FontWeight.w700),
        ),
        const SizedBox(height: Insets.lg),
        for (final h in project.highlights)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 14),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: project.accent,
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
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: Insets.xl),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final t in project.tags) TagPill(t, accent: project.accent),
          ],
        ),
        const SizedBox(height: Insets.xxl),
        Wrap(
          spacing: Insets.md,
          runSpacing: Insets.md,
          children: [
            if (project.id == 'stock-prediction')
              MagneticButton(
                label: 'Run it live →',
                filled: true,
                icon: Icons.science_outlined,
                onPressed: () => context.go('/lab'),
              ),
            if (project.link != null)
              MagneticButton(
                label: 'View on GitHub',
                filled: project.id != 'stock-prediction',
                icon: Icons.arrow_outward_rounded,
                onPressed: () => openUrl(project.link as String),
              ),
            if (project.link == null && project.metric != null)
              TagPill(project.metric as String, accent: project.accent),
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
