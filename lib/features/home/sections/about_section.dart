import 'package:flutter/material.dart';

import '../../../core/data/portfolio_data.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pills.dart';
import '../../../shared/widgets/reveal_on_scroll.dart';
import '../../../shared/widgets/section_header.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    const profile = PortfolioData.profile;
    final isDesktop = context.isDesktop;

    final bio = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final para in profile.about) ...[
          Text(
            para,
            style: AppText.body(
              size: context.responsive<double>(mobile: 16, desktop: 18),
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: Insets.lg),
        ],
        const SizedBox(height: Insets.sm),
        Wrap(
          spacing: Insets.xl,
          runSpacing: Insets.lg,
          children: [
            for (final s in profile.stats)
              StatBlock(value: s.value, label: s.label),
          ],
        ),
      ],
    );

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
                eyebrow: 'about',
                title: 'Polish you can feel,\narchitecture you can trust.',
                accent: AppColors.violet,
              ),
            ),
            const SizedBox(height: Insets.xxl),
            if (isDesktop)
              RevealOnScroll(
                delay: const Duration(milliseconds: 120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 360, child: _ProfileCard()),
                    const SizedBox(width: Insets.xxl),
                    Expanded(child: bio),
                  ],
                ),
              )
            else
              RevealOnScroll(
                delay: const Duration(milliseconds: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProfileCard(),
                    const SizedBox(height: Insets.xl),
                    bio,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    const profile = PortfolioData.profile;
    return GlassContainer(
      padding: const EdgeInsets.all(Insets.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Monogram avatar. Swap this Container for a CircleAvatar /
          // Image.asset once you add a photo (see README).
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: AppColors.auroraGradient,
              borderRadius: BorderRadius.circular(Corners.lg),
            ),
            alignment: Alignment.center,
            child: Text(
              'HK',
              style: AppText.display(
                size: 40,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          Text(
            profile.name,
            style: AppText.display(size: 26, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            profile.roles.first,
            style: AppText.body(size: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: Insets.lg),
          _InfoRow(icon: Icons.place_outlined, text: profile.location),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.mail_outline_rounded, text: profile.email),
          const SizedBox(height: 10),
          const _InfoRow(
              icon: Icons.translate_rounded, text: 'Hindi · English'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.cyan),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: AppText.body(size: 14, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
