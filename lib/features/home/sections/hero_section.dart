import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/data/models.dart';
import '../../../core/data/portfolio_data.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../shared/cursor/cursor_scope.dart';
import '../../../shared/widgets/bird_mascot.dart';
import '../../../shared/widgets/kinetic_text.dart';
import '../../../shared/widgets/magnetic_button.dart';
import '../../../shared/widgets/particle_field.dart';
import '../../../shared/widgets/phone_frame.dart';
import '../../../shared/widgets/scroll_cue.dart';
import '../../../shared/widgets/tilt_card.dart';
import '../../../shared/widgets/typing_text.dart';
import '../../../state/console_cubit.dart';
import '../../../state/navigation_cubit.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.play,
    required this.onNavigate,
  });

  final bool play;
  final void Function(Section) onNavigate;

  @override
  Widget build(BuildContext context) {
    const profile = PortfolioData.profile;
    final nameSize = context.responsive<double>(
      mobile: 46,
      tablet: 76,
      desktop: 104,
    );

    final cursor = CursorScope.maybeOf(context);
    final isDesktop = context.isDesktop;

    final textColumn = _HeroParallax(
      child: _HeroText(
        profile: profile,
        nameSize: nameSize,
        play: play,
        onNavigate: onNavigate,
      ),
    );

    return Stack(
      children: [
        // Ambient constellation — ignored by pointer
        if (!context.reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: ParticleField(
                count: context.responsive<int>(mobile: 35, desktop: 70),
                opacity: 0.45,
                connectLines: true,
                reactRadius: 130.0,
                cursorNotifier: cursor?.position,
              ),
            ),
          ),
        Container(
          constraints: BoxConstraints(minHeight: context.screenHeight),
          padding: EdgeInsets.fromLTRB(
            context.pageGutter,
            context.screenHeight * 0.16,
            isDesktop ? 48 : context.pageGutter,
            Insets.xxl,
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: textColumn),
                    const SizedBox(width: Insets.xl),
                    const _HeroPhone(),
                    const SizedBox(width: 48),
                  ],
                )
              : textColumn,
        ),
      ],
    );
  }
}

// ── Hero text column ───────────────────────────────────────────────────────────

class _HeroText extends StatelessWidget {
  const _HeroText({
    required this.profile,
    required this.nameSize,
    required this.play,
    required this.onNavigate,
  });

  final Profile profile;
  final double nameSize;
  final bool play;
  final void Function(Section) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Availability + metric chips
        const Wrap(
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            _AvailabilityPill(),
            _CountUpChip(),
          ],
        ),
        const SizedBox(height: Insets.xl),
        // Kinetic name
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: KineticText(
            profile.name,
            play: play,
            startDelay: const Duration(milliseconds: 120),
            style: AppText.display(
              size: nameSize,
              weight: FontWeight.w800,
              height: 0.98,
              spacing: -2,
              shadows: const [
                Shadow(
                  color: Color(0xB3000000),
                  blurRadius: 24,
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        _RoleCycler(roles: profile.roles, play: play),
        const SizedBox(height: Insets.md),
        // Typing tagline
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: TypingText(
            phrases: const [
              'shipping cross-platform apps to millions',
              'Flutter · motion · now full-stack',
              'every project here is playable →',
            ],
            style: AppText.body(
              size: context.responsive<double>(mobile: 16, desktop: 19),
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: Insets.xl),
        // CTAs + ⌘K hint
        Wrap(
          spacing: Insets.md,
          runSpacing: Insets.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MagneticButton(
              label: 'View work',
              filled: true,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => onNavigate(Section.work),
            ),
            MagneticButton(
              label: 'Get in touch',
              onPressed: () => onNavigate(Section.contact),
            ),
            const _CmdKPill(),
          ],
        ),
        SizedBox(
            height:
                context.responsive<double>(mobile: Insets.xxl, desktop: 96)),
        const ScrollCue(),
      ],
    );
  }
}

// ── Cycling hero showcase (desktop only) ──────────────────────────────────────

class _HeroPhone extends StatelessWidget {
  const _HeroPhone();

  @override
  Widget build(BuildContext context) {
    return const TiltCard(
      glareColor: AppColors.violet,
      maxTilt: 0.08,
      child: PhoneFrame(
        width: 210,
        child: BirdMascot(),
      ),
    );
  }
}

// ── Parallax ───────────────────────────────────────────────────────────────────

/// Translates the hero content opposite the cursor for a gentle parallax feel.
/// Only active on pointer devices; collapses to Offset.zero on touch/reduceMotion.
///
/// IMPORTANT: always returns the same widget tree shape (ValueListenableBuilder →
/// Transform → child) so that KineticText's element is never remounted when the
/// viewport width crosses the pointer-device breakpoint.
class _HeroParallax extends StatelessWidget {
  const _HeroParallax({required this.child});
  final Widget child;

  static final ValueNotifier<Offset> _zero = ValueNotifier(Offset.zero);

  @override
  Widget build(BuildContext context) {
    final position = CursorScope.maybeOf(context)?.position ?? _zero;
    return ValueListenableBuilder<Offset>(
      valueListenable: position,
      builder: (context, pos, innerChild) {
        final Offset offset;
        if (!context.usePointerInteractions ||
            MediaQuery.of(context).disableAnimations) {
          offset = Offset.zero;
        } else {
          final size = MediaQuery.sizeOf(context);
          offset = Offset(
            (pos.dx / size.width - 0.5) * -10.0,
            (pos.dy / size.height - 0.5) * -8.0,
          );
        }
        return Transform.translate(offset: offset, child: innerChild);
      },
      child: child,
    );
  }
}

// ── Availability pill ──────────────────────────────────────────────────────────

class _AvailabilityPill extends StatefulWidget {
  const _AvailabilityPill();

  @override
  State<_AvailabilityPill> createState() => _AvailabilityPillState();
}

class _AvailabilityPillState extends State<_AvailabilityPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!(MediaQuery.maybeOf(context)?.disableAnimations ?? false)) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(Corners.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.mint.withOpacity(0.6 * _pulse.value),
                      blurRadius: 8,
                      spreadRadius: 2 * _pulse.value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            'Available for new work',
            style: AppText.mono(size: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Count-up metric chip ───────────────────────────────────────────────────────

class _CountUpChip extends StatefulWidget {
  const _CountUpChip();

  @override
  State<_CountUpChip> createState() => _CountUpChipState();
}

class _CountUpChipState extends State<_CountUpChip> {
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('hero-metric-chip'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.4 && !_triggered) {
          setState(() => _triggered = true);
        }
      },
      child: TweenAnimationBuilder<double>(
        duration: context.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 1400),
        tween: Tween(begin: 0.0, end: _triggered ? 1.0 : 0.0),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) {
          final count = (t * 1000000).round();
          final label =
              count >= 1000000 ? '1M+' : '${(count / 1000).round()}K+';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(Corners.pill),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: AppColors.mint, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  '$label downloads shipped',
                  style: AppText.mono(
                      size: 12, color: AppColors.textSecondary, spacing: 0),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── ⌘K hint pill ──────────────────────────────────────────────────────────────

class _CmdKPill extends StatelessWidget {
  const _CmdKPill();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ConsoleCubit>().togglePalette(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.glassHigh,
            borderRadius: BorderRadius.circular(Corners.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_command_key_rounded,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 3),
              Text('K',
                  style: AppText.mono(
                      size: 12, color: AppColors.textTertiary, spacing: 0)),
              const SizedBox(width: 6),
              Text('command palette',
                  style: AppText.mono(
                      size: 12, color: AppColors.textTertiary, spacing: 0)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role cycler ────────────────────────────────────────────────────────────────

class _RoleCycler extends StatefulWidget {
  const _RoleCycler({required this.roles, required this.play});
  final List<String> roles;
  final bool play;

  @override
  State<_RoleCycler> createState() => _RoleCyclerState();
}

class _RoleCyclerState extends State<_RoleCycler> {
  int _index = 0;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant _RoleCycler old) {
    super.didUpdateWidget(old);
    if (widget.play && _timer == null) _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.play && _timer == null) _start();
  }

  void _start() {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted) setState(() => _index = (_index + 1) % widget.roles.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size =
        context.responsive<double>(mobile: 22, tablet: 28, desktop: 32);
    return Row(
      children: [
        Container(
          width: 28,
          height: 2,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            gradient: AppColors.subtleGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Flexible(
          child: AnimatedSwitcher(
            duration: Motion.med,
            transitionBuilder: (child, anim) => ClipRect(
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.6),
                  end: Offset.zero,
                ).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
            ),
            child: Text(
              widget.roles[_index],
              key: ValueKey(_index),
              style: AppText.display(
                size: size,
                weight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
