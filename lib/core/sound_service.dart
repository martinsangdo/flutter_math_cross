import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final _players = <String, AudioPlayer>{};
  static const events = ['tap', 'success', 'try_again', 'win'];
  Future<void> preload() async {
    for (final event in events) {
      try {
        final player = AudioPlayer();
        _players[event] = player;
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource('audio/$event.wav'));
      } catch (_) {
        /* Audio is optional, including browser autoplay restrictions. */
      }
    }
  }

  Future<void> play(String event, {required bool enabled}) async {
    if (!enabled) return;
    try {
      final player = _players[event];
      if (player == null) return;
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      /* A failed sound must never interrupt a puzzle. */
    }
  }

  Future<void> mute() async {
    for (final player in _players.values) {
      await player.pause();
    }
  }

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
  }
}
