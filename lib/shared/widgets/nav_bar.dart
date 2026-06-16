import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/audio/sound_service.dart';
import '../../state/console_cubit.dart';
import '../../state/navigation_cubit.dart';
import '../../state/palette_cubit.dart';
import '../cursor/cursor_scope.dart';
import 'magnetic_button.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key, required this.onNavigate});

  final void Function(Section section) onNavigate;

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  static const _items = [
    Section.about,
    Section.skills,
    Section.work,
    Section.experience,
  ];

  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0x99070710),
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.pageGutter,
            vertical: 14,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _Logo(onTap: () => widget.onNavigate(Section.hero)),
                  const Spacer(),
                  if (!isMobile) ...[
                    for (final s in _items)
                      _NavItem(
                        section: s,
                        onTap: () => widget.onNavigate(s),
                      ),
                    // Lab link
                    _LabNavItem(onTap: () => context.go('/lab')),
                    const SizedBox(width: Insets.md),
                    // Vivid toggle
                    _VividToggle(),
                    const SizedBox(width: Insets.sm),
                    // Sound toggle
                    _SoundToggle(),
                    const SizedBox(width: Insets.sm),
                    // ⌘K hint pill
                    _CmdKPill(
                        onTap: () =>
                            context.read<ConsoleCubit>().togglePalette()),
                    const SizedBox(width: Insets.lg),
                    MagneticButton(
                      label: "Let's talk",
                      onPressed: () => widget.onNavigate(Section.contact),
                    ),
                  ] else
                    _MenuButton(
                      open: _menuOpen,
                      onTap: () => setState(() => _menuOpen = !_menuOpen),
                    ),
                ],
              ),
              if (isMobile)
                AnimatedCrossFade(
                  duration: Motion.fast,
                  crossFadeState: _menuOpen
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  firstChild: _MobileMenu(
                    items: const [..._items, Section.contact],
                    onNavigate: (s) {
                      setState(() => _menuOpen = false);
                      widget.onNavigate(s);
                    },
                    onLab: () {
                      setState(() => _menuOpen = false);
                      context.go('/lab');
                    },
                    onPalette: () {
                      setState(() => _menuOpen = false);
                      context.read<ConsoleCubit>().togglePalette();
                    },
                  ),
                  secondChild: const SizedBox(width: double.infinity),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pointer = context.usePointerInteractions;
    return MouseRegion(
      cursor: pointer ? SystemMouseCursors.none : SystemMouseCursors.click,
      onEnter: (_) => CursorScope.maybeOf(context)?.setHovering(true),
      onExit: (_) => CursorScope.maybeOf(context)?.setHovering(false),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                gradient: AppColors.auroraGradient,
                shape: BoxShape.circle,
              ),
            ),
            ShaderMask(
              shaderCallback: (r) => AppColors.subtleGradient.createShader(r),
              child: Text(
                'HK',
                style: AppText.display(
                  size: 20,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              '.dev',
              style: AppText.display(
                size: 20,
                weight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({required this.section, required this.onTap});
  final Section section;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final pointer = context.usePointerInteractions;
    return BlocBuilder<NavigationCubit, Section>(
      builder: (context, active) {
        final isActive = active == widget.section;
        final highlight = isActive || _hover;
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
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: Motion.fast,
                    width: isActive ? 6 : 0,
                    height: 6,
                    margin: EdgeInsets.only(right: isActive ? 8 : 0),
                    decoration: const BoxDecoration(
                      color: AppColors.cyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(
                    widget.section.label,
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w500,
                      color: highlight
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LabNavItem extends StatefulWidget {
  const _LabNavItem({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_LabNavItem> createState() => _LabNavItemState();
}

class _LabNavItemState extends State<_LabNavItem> {
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
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Lab',
            style: AppText.body(
              size: 15,
              weight: FontWeight.w500,
              color: _hover ? AppColors.violet : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CmdKPill extends StatelessWidget {
  const _CmdKPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.glassHigh,
          borderRadius: BorderRadius.circular(Corners.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '⌘K',
          style: AppText.mono(
              size: 12, color: AppColors.textTertiary, spacing: 0),
        ),
      ),
    );
  }
}

/// Sun/spark button that toggles Vivid mode.
class _VividToggle extends StatelessWidget {
  const _VividToggle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaletteCubit, Palette>(
      builder: (context, palette) {
        final isVivid = palette == Palette.vivid;
        return GestureDetector(
          onTap: () => context.read<PaletteCubit>().toggle(),
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isVivid
                  ? AppColors.violet.withValues(alpha: 0.22)
                  : AppColors.glassHigh,
              borderRadius: BorderRadius.circular(Corners.sm),
              border: Border.all(
                color: isVivid
                    ? AppColors.violetVivid.withValues(alpha: 0.5)
                    : AppColors.border,
              ),
            ),
            child: Icon(
              isVivid ? Icons.auto_awesome_rounded : Icons.wb_sunny_outlined,
              size: 14,
              color: isVivid ? AppColors.violetVivid : AppColors.textTertiary,
            ),
          ),
        );
      },
    );
  }
}

class _SoundToggle extends StatefulWidget {
  const _SoundToggle();

  @override
  State<_SoundToggle> createState() => _SoundToggleState();
}

class _SoundToggleState extends State<_SoundToggle> {
  @override
  Widget build(BuildContext context) {
    final on = SoundService.instance.enabled;
    return GestureDetector(
      onTap: () {
        SoundService.instance.markInteraction();
        SoundService.instance.toggle();
        setState(() {});
      },
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: on ? AppColors.cyan.withValues(alpha: 0.14) : AppColors.glassHigh,
          borderRadius: BorderRadius.circular(Corners.sm),
          border: Border.all(
            color: on ? AppColors.cyan.withValues(alpha: 0.45) : AppColors.border,
          ),
        ),
        child: Icon(
          on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          size: 14,
          color: on ? AppColors.cyan : AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.glassHigh,
          borderRadius: BorderRadius.circular(Corners.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          open ? Icons.close_rounded : Icons.menu_rounded,
          color: AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu({
    required this.items,
    required this.onNavigate,
    required this.onLab,
    required this.onPalette,
  });
  final List<Section> items;
  final void Function(Section) onNavigate;
  final VoidCallback onLab;
  final VoidCallback onPalette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: Insets.lg, bottom: Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in items)
            GestureDetector(
              onTap: () => onNavigate(s),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  s.label,
                  style: AppText.display(size: 24, weight: FontWeight.w700),
                ),
              ),
            ),
          GestureDetector(
            onTap: onLab,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Lab',
                style: AppText.display(
                    size: 24,
                    weight: FontWeight.w700,
                    color: AppColors.violet),
              ),
            ),
          ),
          GestureDetector(
            onTap: onPalette,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⌘K',
                      style: AppText.mono(
                          size: 14,
                          color: AppColors.textTertiary,
                          spacing: 0)),
                  const SizedBox(width: 10),
                  Text('Command palette',
                      style: AppText.body(
                          size: 16, color: AppColors.textTertiary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
