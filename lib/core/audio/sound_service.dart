/// Thin audio service — defaults to muted.
///
/// All play methods are silent no-ops when `enabled == false` or when no sfx
/// assets are bundled. Wire in `audioplayers` + asset files to activate.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  bool enabled = false;
  bool _hadInteraction = false;

  void markInteraction() => _hadInteraction = true;

  void toggle() => enabled = !enabled;

  void playClick() => _play('click');
  void playHover() => _play('hover');

  // ignore: unused_element
  void _play(String _) {
    if (!enabled || !_hadInteraction) return;
    // No-op: sfx assets not bundled. Add audioplayers + assets/sfx/ to enable.
  }
}
