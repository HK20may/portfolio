# Aurora — Harshit Kumawat's Portfolio

An animation-first Flutter portfolio built around a live GLSL **aurora** shader, a
**magnetic cursor**, kinetic typography, and scroll-scrubbed motion. Dark by
design. Single page, plus a routed case-study view for each project.

> Heads up: this was authored in an environment **without a Flutter SDK**, so it
> has **not been compiled or run yet**. The code is written to be correct and
> idiomatic, but you'll want to run `flutter pub get` / `flutter run` and fix any
> small environment-specific issues. See **Running** below.

---

## Signature moments

- **Living aurora background** — a domain-warped FBM shader (`shaders/aurora.frag`)
  that drifts over time and glows toward the cursor. If the shader can't run
  (e.g. Flutter web on the HTML renderer), it **transparently falls back** to a
  hand-painted animated gradient, so something beautiful always renders.
- **Magnetic cursor** — a trailing ring that grows over interactive elements
  (desktop/pointer only; touch devices get normal affordances).
- **Boot curtain** — monogram + filling hairline, then a wipe-up reveal.
- **Kinetic hero** — the name rises in per-character clip-masked glyphs; the role
  line cycles.
- **Tilt cards** — project cards tilt in 3D toward the pointer with a moving glare.
- **Self-drawing timeline** — the experience rail draws itself top-to-bottom as it
  scrolls into view.
- **Shared-element transitions** — tapping a project flies its header into the
  detail page via a `Hero`.
- Reveal-on-scroll, a seamless tech marquee, magnetic buttons, film grain.

Everything respects the OS **"reduce motion"** setting (animations collapse to
their end state).

---

## Architecture

Feature-first folders, `Cubit` for state, `go_router` for navigation.

```
lib/
├─ main.dart                     # entrypoint
├─ app/
│  ├─ app.dart                   # MaterialApp.router + BlocProvider + CursorScope
│  └─ router.dart                # '/' and nested '/work/:id'
├─ core/
│  ├─ theme/                     # app_colors, app_text (type + spacing + motion), app_theme
│  ├─ responsive/                # breakpoints + BuildContext extensions
│  ├─ data/                      # models.dart + portfolio_data.dart  ← your content
│  └─ utils/                     # url launcher helper
├─ state/
│  └─ navigation_cubit.dart      # active-section tracking (drives nav highlight)
├─ shared/
│  ├─ cursor/cursor_scope.dart   # pointer/hover provider + magnetic cursor overlay
│  └─ widgets/                   # aurora_background, kinetic_text, tilt_card,
│                                #   magnetic_button, reveal_on_scroll, glass_container,
│                                #   grain_overlay, nav_bar, section_header, pills, …
└─ features/
   ├─ boot/                      # boot_overlay
   ├─ home/
   │  ├─ home_page.dart          # stacks aurora + scroll + grain + nav + boot
   │  └─ sections/               # hero, about, skills, work, experience, contact
   └─ work/project_detail_page.dart
shaders/aurora.frag              # the GLSL aurora
```

---

## Running

```bash
flutter pub get
flutter run            # mobile/desktop
# Web — use the CanvasKit renderer so the shader runs:
flutter run -d chrome --web-renderer canvaskit
```

If dependency versions clash with your installed Flutter:

```bash
flutter pub upgrade --major-versions
```

**Dependencies:** `flutter_bloc`, `go_router`, `google_fonts`, `flutter_animate`
(declared for convenience; currently unused — safe to remove), `visibility_detector`,
`url_launcher`. Fonts (Syne / Inter / JetBrains Mono) are fetched at runtime by
`google_fonts`; for offline/perf you can bundle them as assets instead.

---

## Make it yours (the three knobs)

1. **Content** → `lib/core/data/portfolio_data.dart`
   Profile, socials, stats, skill groups, experience, and projects all live here.
   Edit this file only — no widget changes needed. (Already populated from your
   résumé: Polaris / NowFloats / Fraazo, the personal projects, your stack & links.)

2. **Palette** → `lib/core/theme/app_colors.dart`
   Change `violet` / `cyan` / `pink` to re-skin everything. **If you change those
   three, update the matching `vec3`s in `shaders/aurora.frag`** so the shader stays
   in sync.

3. **The aurora itself** → `shaders/aurora.frag`
   Tune `uTime` multipliers for speed, the `fbm` octaves for detail, or the mix
   weights for how strongly each color shows.

### Adding a profile photo

There's no photo in the résumé, so the About card and boot screen use an **"HK"
monogram**. To use a real image: drop it in `assets/`, declare it in `pubspec.yaml`
under `flutter: assets:`, then in `lib/features/home/sections/about_section.dart`
swap the monogram `Container` in `_ProfileCard` for a `ClipRRect`/`CircleAvatar`
with `Image.asset(...)`.

---

## Notes & intentional choices

- **Dark-only by design.** A half-built light mode is worse than none, so there's
  no theme toggle. To add one later: introduce a `ThemeCubit`, a light `AppColors`
  variant + light `ThemeData`, and switch on it in `app.dart`.
- **No numbered section markers.** Eyebrows are styled like source comments
  (`// about`) — a nod to the subject rather than a generic `01 / 02 / 03`.
- **Localization (EN/HI).** You're bilingual; this build ships English only to keep
  scope tight. To add Hindi later, wire up `flutter_localizations` + `intl` and move
  the strings in `portfolio_data.dart` behind a locale.
- **Social links are text**, not brand icons — no icon-pack dependency, cleaner
  editorial feel.

Built with Flutter — shader and motion by hand.
