import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../core/theme/app_colors.dart';
import '../../state/navigation_cubit.dart';
import '../../state/scroll_intent_cubit.dart';
import '../../shared/widgets/aurora_background.dart';
import '../../shared/widgets/grain_overlay.dart';
import '../../shared/widgets/nav_bar.dart';
import '../boot/boot_overlay.dart';
import 'sections/about_section.dart';
import 'sections/contact_section.dart';
import 'sections/experience_section.dart';
import 'sections/hero_section.dart';
import 'sections/skills_section.dart';
import 'sections/work_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  final Map<Section, GlobalKey> _keys = {
    for (final s in Section.values) s: GlobalKey(),
  };
  final Map<Section, double> _fractions = {};

  bool _booted = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    // Handle intent that was set before this page mounted (e.g. from /lab).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final intent = context.read<ScrollIntentCubit>().state;
      if (intent != null) {
        _scrollTo(intent);
        context.read<ScrollIntentCubit>().clear();
      }
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    _scrollProgress.value = (_scroll.offset / max).clamp(0.0, 1.0);
  }

  void _scrollTo(Section section) {
    final ctx = _keys[section]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      alignment: section == Section.hero ? 0.0 : 0.02,
    );
  }

  void _onVisibility(Section section, double fraction) {
    _fractions[section] = fraction;
    Section best = Section.hero;
    double bestFraction = -1;
    _fractions.forEach((s, f) {
      if (f > bestFraction) {
        bestFraction = f;
        best = s;
      }
    });
    if (bestFraction > 0) context.read<NavigationCubit>().setActive(best);
  }

  Widget _block(Section section, Widget child) {
    return VisibilityDetector(
      key: ValueKey('vd-${section.name}'),
      onVisibilityChanged: (info) =>
          _onVisibility(section, info.visibleFraction),
      child: KeyedSubtree(key: _keys[section], child: child),
    );
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scrollProgress.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScrollIntentCubit, Section?>(
      listener: (context, section) {
        if (section == null) return;
        // Post-frame so the keys are definitely attached.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollTo(section);
          context.read<ScrollIntentCubit>().clear();
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Ambient shader behind everything — scales gently on scroll for parallax.
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<double>(
                  valueListenable: _scrollProgress,
                  builder: (context, progress, child) {
                    if (MediaQuery.of(context).disableAnimations) return child!;
                    return Transform.scale(
                      scale: 1.0 + progress * 0.06,
                      child: child,
                    );
                  },
                  child: const AuroraBackground(),
                ),
              ),
            ),

            // Scrollable content.
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  children: [
                    _block(
                      Section.hero,
                      HeroSection(play: _booted, onNavigate: _scrollTo),
                    ),
                    _block(Section.about, const AboutSection()),
                    _block(Section.skills, const SkillsSection()),
                    _block(Section.work, const WorkSection()),
                    _block(Section.experience, const ExperienceSection()),
                    _block(
                      Section.contact,
                      ContactSection(onNavigate: _scrollTo),
                    ),
                  ],
                ),
              ),
            ),

            // Film grain.
            const Positioned.fill(child: GrainOverlay()),

            // Floating nav.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NavBar(onNavigate: _scrollTo),
            ),

            // Scroll progress bar — 2.5px gradient strip at the very top.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 2.5,
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollProgress,
                builder: (context, progress, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.auroraGradient,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // First-load curtain.
            if (!_booted)
              Positioned.fill(
                child: BootOverlay(
                  onComplete: () {
                    if (mounted) setState(() => _booted = true);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
