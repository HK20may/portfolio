import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/data/models.dart';
import '../../core/data/portfolio_data.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/launch.dart';
import '../../state/console_cubit.dart';
import '../../state/palette_cubit.dart';
import '../../state/scroll_intent_cubit.dart';
import '../../state/navigation_cubit.dart';

// ── Command names for Tab autocomplete ──────────────────────────────────────
const _cmds = [
  'help', 'whoami', 'about', 'skills', 'experience', 'projects', 'contact',
  'socials', 'ls', 'cat', 'goto', 'open', 'lab', 'play', 'theme', 'clear',
  'exit', 'close', 'github', 'neofetch', 'matrix', 'sudo', 'echo', 'date',
];

class TerminalOverlay extends StatefulWidget {
  const TerminalOverlay({super.key});

  @override
  State<TerminalOverlay> createState() => _TerminalOverlayState();
}

class _TerminalOverlayState extends State<TerminalOverlay> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  final _kbFocus = FocusNode();
  final List<_Line> _lines = [];
  final List<String> _history = [];
  int _histIdx = -1;
  final DateTime _startTime = DateTime.now();

  static const _prompt = 'harshit@portfolio:~\$ ';

  @override
  void initState() {
    super.initState();
    _print('Aurora Terminal v2.0', AppColors.violet);
    _print('Type "help" for commands. Tab autocomplete. ↑↓ history.', AppColors.textTertiary);
    _print('', AppColors.textSecondary);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _print(String text, Color color) {
    if (!mounted) return;
    setState(() => _lines.add(_Line(text, color)));
    _scrollToBottom();
  }

  void _submit(String raw) {
    final input = raw.trim();
    _controller.clear();
    if (input.isEmpty) return;
    _history.insert(0, input);
    _histIdx = -1;
    _print('$_prompt$input', AppColors.textPrimary);
    _runCommand(input.toLowerCase().trim(), input.trim());
  }

  void _runCommand(String cmd, String raw) {
    final p = PortfolioData.profile;

    // ── Multi-word commands ─────────────────────────────────────────────────
    if (cmd.startsWith('goto ')) {
      final target = cmd.substring(5).trim();
      final map = <String, Section>{
        'home': Section.hero,
        'about': Section.about,
        'skills': Section.skills,
        'work': Section.work,
        'experience': Section.experience,
        'contact': Section.contact,
      };
      final s = map[target];
      if (s != null) {
        _print('Navigating to $target…', AppColors.mint);
        context.read<ScrollIntentCubit>().request(s);
        context.go('/');
        context.read<ConsoleCubit>().dismiss();
      } else {
        _print('Unknown section: $target. Try: ${map.keys.join(", ")}', AppColors.pink);
      }
      return;
    }

    if (cmd.startsWith('open ')) {
      final target = cmd.substring(5).trim();
      SocialLink? match;
      for (final s in p.socials) {
        if (s.label.toLowerCase().contains(target) ||
            target.contains(s.label.toLowerCase().split('/').first.trim().toLowerCase())) {
          match = s;
          break;
        }
      }
      if (match == null && (target == 'x' || target == 'twitter')) {
        try {
          match = p.socials.firstWhere((s) => s.label.toLowerCase().contains('twitter'));
        } catch (_) {}
      }
      if (match != null) {
        _print('Opening ${match.label}…', AppColors.mint);
        openUrl(match.url);
      } else {
        _print('Unknown target: $target. Try: github, linkedin, x, email', AppColors.pink);
      }
      return;
    }

    if (cmd.startsWith('play')) {
      final parts = cmd.split(' ');
      if (parts.length == 1) {
        context.read<ConsoleCubit>().openGame();
      } else {
        context.read<ConsoleCubit>().openGame(parts[1]);
      }
      return;
    }

    if (cmd.startsWith('theme ')) {
      final arg = cmd.substring(6).trim();
      if (arg == 'vivid') {
        context.read<PaletteCubit>().set(Palette.vivid);
        _print('Vivid mode ✦', AppColors.violetVivid);
      } else if (arg == 'calm') {
        context.read<PaletteCubit>().set(Palette.calm);
        _print('Calm mode.', AppColors.textSecondary);
      } else {
        _print('Usage: theme <vivid|calm>', AppColors.pink);
      }
      return;
    }

    if (cmd.startsWith('sudo ')) {
      _print('permission denied 😏', AppColors.pink);
      return;
    }

    if (cmd.startsWith('echo ')) {
      _print(raw.substring(5).trim(), AppColors.textPrimary);
      return;
    }

    if (cmd.startsWith('cat ')) {
      final arg = cmd.substring(4).trim();
      if (arg == 'resume') {
        _print('${p.name} — ${p.roles.first}', AppColors.textPrimary);
        _print('${p.location} · ${p.email}', AppColors.textSecondary);
        _print('', AppColors.textSecondary);
        _print('4+ years building cross-platform Flutter apps', AppColors.textSecondary);
        _print('Android · iOS · Web · Desktop', AppColors.textSecondary);
        _print('Shipped to 1M+ users across government & commercial products', AppColors.textSecondary);
        if (p.socials.isNotEmpty) _print('GitHub: ${p.socials.first.url}', AppColors.cyan);
      } else {
        _print('cat: $arg: No such file', AppColors.pink);
      }
      return;
    }

    // ── Single-word commands ────────────────────────────────────────────────
    switch (cmd) {
      case 'help':
        _print('── Navigation ───────────────────────────', AppColors.cyan);
        _print('  goto <section>   open <social>   lab', AppColors.textSecondary);
        _print('── Info ─────────────────────────────────', AppColors.cyan);
        _print('  whoami  about  skills  experience  projects  contact', AppColors.textSecondary);
        _print('  socials  ls  cat resume  neofetch', AppColors.textSecondary);
        _print('── Fun ──────────────────────────────────', AppColors.cyan);
        _print('  play [game]  theme <vivid|calm>  github  matrix', AppColors.textSecondary);
        _print('  echo <text>  date  sudo <anything>', AppColors.textSecondary);
        _print('  clear  exit', AppColors.textSecondary);

      case 'whoami':
        _print('${p.name} — ${p.roles.first}', AppColors.textPrimary);
        _print('${p.location} · ${p.email}', AppColors.textSecondary);

      case 'about':
        for (final para in p.about) {
          _print(para, AppColors.textSecondary);
          _print('', AppColors.textSecondary);
        }

      case 'skills':
        for (final g in PortfolioData.skillGroups) {
          _print('${g.title}:', AppColors.cyan);
          _print('  ${g.items.join("  ·  ")}', AppColors.textSecondary);
        }

      case 'experience':
        for (final e in PortfolioData.experiences) {
          _print('${e.company}  ·  ${e.role}  (${e.period})', AppColors.cyan);
          _print('  ${e.blurb}', AppColors.textSecondary);
          _print('', AppColors.textSecondary);
        }

      case 'projects':
        for (final proj in PortfolioData.projects) {
          _print('${proj.title}  (${proj.year})', AppColors.violet);
          _print('  ${proj.subtitle}', AppColors.textSecondary);
          _print('  Tags: ${proj.tags.join(", ")}', AppColors.textTertiary);
        }

      case 'contact':
        _print('Email: ${p.email}', AppColors.cyan);
        _print('Phone: ${p.phone}', AppColors.textSecondary);

      case 'socials':
        for (final s in p.socials) {
          _print('${s.label}:  ${s.url}', AppColors.textSecondary);
        }

      case 'ls':
        _print('about/    skills/    work/    experience/    contact/', AppColors.textSecondary);

      case 'date':
        _print(DateTime.now().toLocal().toString().split('.').first, AppColors.textSecondary);

      case 'github':
        _print('Fetching github.com/HK20may…', AppColors.textTertiary);
        _runAsync(_fetchGitHub);

      case 'neofetch':
        _printNeofetch();

      case 'matrix':
        _launchMatrix();

      case 'lab':
        _print('Opening the Lab…', AppColors.mint);
        context.go('/lab');
        context.read<ConsoleCubit>().dismiss();

      case 'clear':
        setState(() => _lines.clear());

      case 'exit':
      case 'close':
        context.read<ConsoleCubit>().dismiss();

      default:
        _print('command not found: ${raw.split(" ").first}', AppColors.pink);
        _print('Type "help" for available commands.', AppColors.textTertiary);
    }
  }

  // ── Async helpers ──────────────────────────────────────────────────────────

  void _runAsync(Future<void> Function() fn) {
    fn().catchError((e) {
      if (mounted) _print("couldn't reach GitHub right now", AppColors.pink);
    });
  }

  Future<void> _fetchGitHub() async {
    try {
      final res =
          await http.get(Uri.parse('https://api.github.com/users/HK20may'));
      if (res.statusCode != 200) {
        _print("GitHub returned ${res.statusCode} — try again later.", AppColors.pink);
        return;
      }
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      _print('── github.com/${j["login"]} ──────────────', AppColors.cyan);
      _print('  name:      ${j["name"] ?? j["login"]}', AppColors.textSecondary);
      if ((j['bio'] as String?)?.isNotEmpty == true) {
        _print('  bio:       ${j["bio"]}', AppColors.textSecondary);
      }
      _print(
          '  repos:     ${j["public_repos"]}  ·  followers: ${j["followers"]}  ·  following: ${j["following"]}',
          AppColors.textSecondary);

      final rRes = await http.get(Uri.parse(
          'https://api.github.com/users/HK20may/repos?sort=updated&per_page=5'));
      final repos =
          (jsonDecode(rRes.body) as List).cast<Map<String, dynamic>>();
      _print('', AppColors.textSecondary);
      _print('  recent repos:', AppColors.cyan);
      for (final r in repos) {
        final stars = r['stargazers_count'] ?? 0;
        final lang = r['language'] ?? '—';
        _print('    ${r["name"]}  $stars★  $lang', AppColors.textSecondary);
      }
    } catch (_) {
      _print("couldn't reach GitHub right now", AppColors.pink);
    }
  }

  void _printNeofetch() {
    final elapsed = DateTime.now().difference(_startTime);
    final uptime = '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s';
    _print(' _  _  _  __              ', AppColors.mint);
    _print('| || || |/ /              ', AppColors.mint);
    _print('|  _  | \' <   harshit@portfolio', AppColors.mint);
    _print('|_||_||_|\\_\\  ─────────────────────', AppColors.mint);
    _print('             OS:       Flutter (Dart 3)', AppColors.textSecondary);
    _print('             Role:     Cross-Platform Engineer', AppColors.textSecondary);
    _print('             Location: Jaipur, IN', AppColors.textSecondary);
    _print('             Stack:    Flutter · BLoC · Firebase · Riverpod', AppColors.textSecondary);
    _print('             Shipped:  1M+ downloads', AppColors.textSecondary);
    _print('             Uptime:   $uptime', AppColors.textSecondary);
  }

  void _launchMatrix() {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _MatrixRain(onDismiss: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  // ── History & autocomplete ─────────────────────────────────────────────────

  void _historyUp() {
    if (_history.isEmpty) return;
    setState(() {
      _histIdx = (_histIdx + 1).clamp(0, _history.length - 1);
      _controller.text = _history[_histIdx];
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  void _historyDown() {
    setState(() {
      _histIdx -= 1;
      if (_histIdx < 0) {
        _histIdx = -1;
        _controller.text = '';
      } else {
        _controller.text = _history[_histIdx];
      }
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  void _autocomplete() {
    final text = _controller.text.trim().toLowerCase();
    if (text.isEmpty) return;
    final matches = _cmds.where((c) => c.startsWith(text)).toList();
    if (matches.length == 1) {
      _controller.text = matches.first;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    } else if (matches.length > 1) {
      _print(matches.join('    '), AppColors.textTertiary);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _kbFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = context.responsive<double>(mobile: double.infinity, tablet: 640, desktop: 720);

    return Center(
      child: SizedBox(
        width: w == double.infinity
            ? MediaQuery.sizeOf(context).width - context.pageGutter * 2
            : w,
        height: context.responsive<double>(mobile: 460, desktop: 540),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Corners.lg),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xE6080810),
                borderRadius: BorderRadius.circular(Corners.lg),
                border: Border.all(color: AppColors.borderStrong),
              ),
              child: KeyboardListener(
                focusNode: _kbFocus,
                autofocus: false,
                onKeyEvent: (e) {
                  if (e is! KeyDownEvent && e is! KeyRepeatEvent) return;
                  if (e.logicalKey == LogicalKeyboardKey.arrowUp) _historyUp();
                  if (e.logicalKey == LogicalKeyboardKey.arrowDown) _historyDown();
                  if (e.logicalKey == LogicalKeyboardKey.tab) _autocomplete();
                  if (e.logicalKey == LogicalKeyboardKey.escape) {
                    context.read<ConsoleCubit>().dismiss();
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Insets.lg, vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          _Dot(Colors.red),
                          const SizedBox(width: 6),
                          _Dot(Colors.amber),
                          const SizedBox(width: 6),
                          _Dot(Colors.green),
                          const SizedBox(width: Insets.lg),
                          Text('terminal — harshit@portfolio',
                              style: AppText.mono(size: 12, color: AppColors.textTertiary, spacing: 0.5)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.read<ConsoleCubit>().dismiss(),
                            child: const Icon(Icons.close_rounded,
                                color: AppColors.textTertiary, size: 18),
                          ),
                        ],
                      ),
                    ),
                    // Scrollback
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(Insets.md),
                        itemCount: _lines.length,
                        itemBuilder: (_, i) {
                          final l = _lines[i];
                          return Text(l.text,
                              style: AppText.mono(size: 13, color: l.color, spacing: 0));
                        },
                      ),
                    ),
                    // Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Text(_prompt,
                              style: AppText.mono(size: 13, color: AppColors.violet, spacing: 0)),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              style: AppText.mono(size: 13, color: AppColors.textPrimary, spacing: 0),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Traffic-light dot ──────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
      );
}

// ── Matrix rain overlay ────────────────────────────────────────────────────

class _MatrixRain extends StatefulWidget {
  const _MatrixRain({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  State<_MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<_MatrixRain>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Column> _columns = [];
  Duration _last = Duration.zero;
  double _elapsed = 0;
  final _rng = Random();

  static const _chars =
      '01アイウエオカキクケコサシスセソタチツテトナニヌネノ';

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    // Auto-dismiss after 6 s
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) widget.onDismiss();
    });
  }

  void _spawn(Size size) {
    if (_columns.isNotEmpty) return;
    const colW = 18.0;
    final n = (size.width / colW).floor();
    for (var i = 0; i < n; i++) {
      _columns.add(_Column(
        x: i * colW + colW / 2,
        speed: 60 + _rng.nextDouble() * 120,
        head: -_rng.nextDouble() * 400,
        length: 8 + _rng.nextInt(16),
        chars: List.generate(28, (_) => _chars[_rng.nextInt(_chars.length)]),
      ));
    }
  }

  void _tick(Duration elapsed) {
    if (_last == Duration.zero) { _last = elapsed; return; }
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _elapsed += dt;
    for (final c in _columns) c.head += c.speed * dt;
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (_) => widget.onDismiss(),
        child: ColoredBox(
          color: const Color(0xEA000000),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              _spawn(constraints.biggest);
              return CustomPaint(
                painter: _MatrixPainter(columns: _columns, size: constraints.biggest),
                size: constraints.biggest,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Column {
  _Column({
    required this.x,
    required this.speed,
    required this.head,
    required this.length,
    required this.chars,
  });
  final double x, speed;
  double head;
  final int length;
  final List<String> chars;
}

class _MatrixPainter extends CustomPainter {
  const _MatrixPainter({required this.columns, required this.size});
  final List<_Column> columns;
  final Size size;

  static const _charH = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (final col in columns) {
      final headRow = (col.head / _charH).floor();
      for (var i = 0; i < col.length; i++) {
        final row = headRow - i;
        final y = row * _charH;
        if (y < -_charH || y > size.height) continue;
        final charIdx = (row.abs()) % col.chars.length;
        final char = col.chars[charIdx];
        final brightness = i == 0 ? 1.0 : (1 - i / col.length) * 0.75;
        final color = i == 0
            ? Colors.white.withValues(alpha: brightness)
            : Color.fromARGB(
                (brightness * 255).round(),
                0,
                (200 * brightness).round(),
                0,
              );
        final tp = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: color,
              fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(col.x - tp.width / 2, y));
      }
    }
  }

  @override
  bool shouldRepaint(_MatrixPainter old) => true;
}

class _Line {
  const _Line(this.text, this.color);
  final String text;
  final Color color;
}
