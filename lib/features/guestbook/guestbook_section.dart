import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/magnetic_button.dart';
import 'guestbook_service.dart';

/// Live guestbook widget — uses [guestbookService] (InMemoryGuestbook by
/// default, swap for FirestoreGuestbook once firebase is configured).
class GuestbookSection extends StatefulWidget {
  const GuestbookSection({super.key});

  @override
  State<GuestbookSection> createState() => _GuestbookSectionState();
}

class _GuestbookSectionState extends State<GuestbookSection> {
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String? _nameErr;
  String? _msgErr;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final msg = _msgCtrl.text.trim();

    setState(() {
      _nameErr = name.isEmpty
          ? 'Name is required'
          : name.length > 40
              ? 'Max 40 characters'
              : null;
      _msgErr = msg.isEmpty
          ? 'Message is required'
          : msg.length > 200
              ? 'Max 200 characters'
              : null;
    });

    if (_nameErr != null || _msgErr != null) return;

    setState(() => _submitting = true);
    try {
      await guestbookService.add(name, msg);
      _nameCtrl.clear();
      _msgCtrl.clear();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildForm(),
        const SizedBox(height: Insets.lg),
        _buildList(),
        const SizedBox(height: Insets.sm),
        Text(
          '✦ Currently learning Go to back live features like this with a REST/gRPC service.',
          style: AppText.mono(size: 11, color: AppColors.textTertiary, spacing: 0.2),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign the guestbook',
              style: AppText.display(size: 16, weight: FontWeight.w700)),
          const SizedBox(height: Insets.md),
          _Field(
            controller: _nameCtrl,
            hint: 'Your name',
            error: _nameErr,
            maxLength: 40,
            maxLines: 1,
          ),
          const SizedBox(height: Insets.sm),
          _Field(
            controller: _msgCtrl,
            hint: 'Leave a note… (max 200 chars)',
            error: _msgErr,
            maxLength: 200,
            maxLines: 3,
          ),
          const SizedBox(height: Insets.md),
          _submitting
              ? const SizedBox(
                  height: 24,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.violet, strokeWidth: 1.5),
                    ),
                  ),
                )
              : MagneticButton(
                  label: '✍  Sign',
                  filled: true,
                  onPressed: _submit,
                ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<GuestEntry>>(
      stream: guestbookService.watch(),
      builder: (context, snap) {
        final entries = snap.data ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: Text('No entries yet — be the first!',
                  style: AppText.body(
                      size: 14, color: AppColors.textTertiary)),
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.border, height: 1),
            itemBuilder: (context, i) => _EntryTile(entry: entries[i]),
          ),
        );
      },
    );
  }
}

// ── Form field ─────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.error,
    this.maxLength,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final String? error;
  final int? maxLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: AppText.body(size: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(size: 14, color: AppColors.textTertiary),
        errorText: error,
        counterText: '',
        filled: true,
        fillColor: AppColors.glassHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: const BorderSide(color: AppColors.violet),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.md),
          borderSide: const BorderSide(color: AppColors.pink),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: Insets.md, vertical: Insets.sm),
      ),
    );
  }
}

// ── Entry tile ─────────────────────────────────────────────────────────────────

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final GuestEntry entry;

  static String _timeAgo(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.violet.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.violet.withOpacity(0.35)),
            ),
            child: Center(
              child: Text(
                entry.name.isNotEmpty
                    ? entry.name[0].toUpperCase()
                    : '?',
                style: AppText.mono(
                    size: 13, color: AppColors.violet, spacing: 0),
              ),
            ),
          ),
          const SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: AppText.body(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(entry.at),
                      style: AppText.mono(
                          size: 10,
                          color: AppColors.textTertiary,
                          spacing: 0),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  entry.message,
                  style: AppText.body(
                      size: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
