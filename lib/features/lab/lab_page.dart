import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/grain_overlay.dart';
import '../../shared/widgets/nav_bar.dart';
import '../../shared/widgets/reveal_on_scroll.dart';
import '../../state/navigation_cubit.dart';
import '../../state/scroll_intent_cubit.dart';
import 'monte_carlo/monte_carlo_sim.dart';
import 'widgets/boids_field.dart';
import 'widgets/dot_matrix.dart';
import 'widgets/draw_canvas.dart';
import 'widgets/particle_field.dart';
import 'widgets/shader_lab.dart';

class LabPage extends StatelessWidget {
  const LabPage({super.key});

  void _navTo(BuildContext context, Section section) {
    context.read<ScrollIntentCubit>().request(section);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: AuroraBackground()),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.pageGutter,
                  vertical: context.responsive(
                      mobile: Insets.xxl, desktop: Insets.xxxl),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: Breakpoints.maxContent),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back + top spacer for nav
                        SizedBox(
                          height: context.responsive<double>(
                              mobile: 72, desktop: 96),
                        ),
                        // Back button
                        GestureDetector(
                          onTap: () => context.go('/'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_rounded,
                                  size: 16, color: AppColors.textTertiary),
                              const SizedBox(width: 8),
                              Text('Back to portfolio',
                                  style: AppText.body(
                                      size: 14,
                                      color: AppColors.textTertiary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: Insets.xl),
                        // Header
                        Text('// the lab',
                            style: AppText.mono(
                                size: 13, color: AppColors.violet)),
                        const SizedBox(height: Insets.md),
                        Text(
                          'Experiments & toys.',
                          style: AppText.display(
                            size: context.responsive<double>(
                                mobile: 36, tablet: 48, desktop: 60),
                            weight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: Insets.md),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Text(
                            'Things I build to push Flutter — shaders, physics, generative art, and a little math.',
                            style: AppText.body(
                                size: 17,
                                color: AppColors.textSecondary,
                                height: 1.6),
                          ),
                        ),
                        const SizedBox(height: Insets.xxl),
                        // Exhibits
                        const _Exhibit(
                          title: 'Ripple Field',
                          caption: 'CustomPainter + wave physics — click to ripple',
                          child: DotMatrix(),
                        ),
                        const SizedBox(height: Insets.xxl),
                        const _Exhibit(
                          title: 'Particle Field',
                          caption: 'Ticker-driven particle system',
                          child: ParticleField(),
                        ),
                        const SizedBox(height: Insets.xxl),
                        const _Exhibit(
                          title: 'Shader Lab',
                          caption: 'GLSL fragment shader with live uniforms',
                          child: ShaderLab(),
                        ),
                        const SizedBox(height: Insets.xxl),
                        const _Exhibit(
                          title: 'Monte Carlo Simulator',
                          caption:
                              'Real stock data · GBM forward paths in a background isolate',
                          child: MonteCarloSim(),
                        ),
                        const SizedBox(height: Insets.xxl),
                        const _Exhibit(
                          title: 'Boids Flocking',
                          caption: 'Boids — separation, alignment & cohesion produce emergent flocking',
                          child: BoidsField(),
                        ),
                        const SizedBox(height: Insets.xxl),
                        const _Exhibit(
                          title: 'Generative Canvas',
                          caption: 'Drag to paint — fading trails',
                          child: DrawCanvas(),
                        ),
                        SizedBox(
                            height: context.responsive(
                                mobile: Insets.xxl, desktop: Insets.xxxl)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(child: GrainOverlay()),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: NavBar(
              onNavigate: (s) => _navTo(context, s),
            ),
          ),
        ],
      ),
    );
  }
}

class _Exhibit extends StatelessWidget {
  const _Exhibit({
    required this.title,
    required this.caption,
    required this.child,
  });
  final String title;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RevealOnScroll(
      child: GlassContainer(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: AppText.display(
                          size: 22, weight: FontWeight.w700)),
                ),
                Text(caption,
                    style: AppText.mono(
                        size: 11,
                        color: AppColors.textTertiary,
                        spacing: 0.4)),
              ],
            ),
            const SizedBox(height: Insets.lg),
            child,
          ],
        ),
      ),
    );
  }
}
