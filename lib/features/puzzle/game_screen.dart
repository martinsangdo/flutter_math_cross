import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ad_placeholders.dart';
import '../../core/sound_service.dart';
import '../../core/theme.dart';
import '../../data/game_store.dart';
import 'game_session.dart';
import 'puzzle.dart';
import 'puzzle_board.dart';

final soundProvider = Provider<SoundService>((ref) {
  final sound = SoundService();
  unawaited(sound.preload());
  ref.onDispose(() => unawaited(sound.dispose()));
  return sound;
});

Puzzle _loadPuzzle((int, bool, int) request) => request.$2
    ? LevelFactory().endless(request.$1, request.$3)
    : LevelFactory().campaign(request.$1);

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.level, this.endless = false});
  final int level;
  final bool endless;
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  GameSession? _game;
  bool _checked = false, _won = false, _loadingFailed = false;
  String _message = 'Tap an empty tile to begin.';
  final _focus = FocusNode();
  String get _key =>
      '${widget.endless ? 'endless' : 'campaign'}:${widget.level}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(storeProvider);
    try {
      final puzzle = await compute(_loadPuzzle, (
        widget.level,
        widget.endless,
        store.endlessSeed,
      ));
      if (!mounted) return;
      setState(() {
        _game = GameSession(puzzle, draft: store.draft(_key));
      });
    } catch (_) {
      if (mounted) setState(() => _loadingFailed = true);
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _sound(String event) => unawaited(
    ref.read(soundProvider).play(event, enabled: ref.read(storeProvider).sound),
  );
  void _edit(VoidCallback action) {
    if (_won || _game == null) return;
    final before = _game!.puzzle.equations
        .where((e) => e.satisfied({..._game!.puzzle.givens, ..._game!.entries}))
        .length;
    setState(() {
      action();
      _checked = false;
      _message = 'Looking good. Follow the crossing clues.';
    });
    ref.read(storeProvider).saveDraft(_key, _game!.entries);
    final after = _game!.puzzle.equations
        .where((e) => e.satisfied({..._game!.puzzle.givens, ..._game!.entries}))
        .length;
    _sound(after > before ? 'success' : 'tap');
  }

  void _check() {
    final game = _game!;
    if (game.solved) {
      _finish();
    } else {
      setState(() {
        _checked = true;
        _message = game.entries.length < game.puzzle.blanks.length
            ? 'A few tiles still need a number. You’ve got this.'
            : 'Not quite yet. Check the equations marked with !.';
      });
      _sound('try_again');
    }
  }

  Future<void> _finish({bool previewSkip = false}) async {
    if (_won) return;
    setState(() => _won = true);
    if (!previewSkip) {
      ref.read(storeProvider).complete(widget.level, endless: widget.endless);
      _sound('win');
    }
    final hasNext = widget.endless || widget.level < LevelFactory.campaignCount;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(
            previewSkip ? 'Preview the next puzzle' : 'Beautifully solved!',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!previewSkip) ...[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_rounded, size: 46, color: Palette.gold),
                      Icon(Icons.star_rounded, size: 56, color: Palette.gold),
                      Icon(Icons.star_rounded, size: 46, color: Palette.gold),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  previewSkip
                      ? 'This preview shortcut does not earn stars or unlock campaign levels.'
                      : hasNext
                      ? 'Every number found its place. Ready for another little challenge?'
                      : 'All five Math Cross puzzles, connected. Keep exploring with Endless play.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'levels'),
              child: const Text('Back to puzzles'),
            ),
            if (hasNext)
              FilledButton(
                onPressed: () => Navigator.pop(context, 'next'),
                child: const Text('Next puzzle'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'next') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              GameScreen(level: widget.level + 1, endless: widget.endless),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _game == null || _won) {
      return KeyEventResult.ignored;
    }
    if (kIsWeb && event.character == r'$') {
      if (widget.endless || widget.level < LevelFactory.campaignCount) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                GameScreen(level: widget.level + 1, endless: widget.endless),
          ),
        );
      } else {
        Navigator.pop(context);
      }
      return KeyEventResult.handled;
    }
    final digit = int.tryParse(event.character ?? '');
    if (digit != null) {
      _edit(() => _game!.digit(digit));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      _edit(() => _game!.erase());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _check();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _game!.next());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    ref.listen(storeProvider.select((s) => s.sound), (previous, next) {
      if (!next) unawaited(ref.read(soundProvider).mute());
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.endless
              ? 'Endless · ${widget.level}'
              : 'Level ${widget.level.toString().padLeft(2, '0')}',
        ),
        actions: const [HintButton(), SizedBox(width: 12)],
      ),
      bottomNavigationBar: const BannerPlaceholder(),
      body: SafeArea(
        child: game == null
            ? Center(
                child: _loadingFailed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Let’s give this puzzle another try.'),
                          TextButton(
                            onPressed: () {
                              setState(() => _loadingFailed = false);
                              _load();
                            },
                            child: const Text('Try again'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              )
            : Focus(
                focusNode: _focus,
                autofocus: true,
                onKeyEvent: _handleKey,
                child: Content(
                  width: 500,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              LevelFactory.chapters[game.puzzle.chapter],
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const Icon(Icons.spa_outlined, color: Palette.teal),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Make every equation true. Take your time.'),
                      const SizedBox(height: 20),
                      SurfaceCard(
                        padding: 8,
                        child: PuzzleBoard(
                          puzzle: game.puzzle,
                          entries: game.entries,
                          selected: game.selected,
                          checked: _checked,
                          onSelect: (cell) {
                            setState(() => game.select(cell));
                            _focus.requestFocus();
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Palette.muted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: game.canUndo
                                ? () => _edit(game.undo)
                                : null,
                            icon: const Icon(Icons.undo_rounded, size: 20),
                            label: const Text('Undo'),
                          ),
                          TextButton.icon(
                            onPressed: () => _edit(game.erase),
                            icon: const Icon(
                              Icons.backspace_outlined,
                              size: 20,
                            ),
                            label: const Text('Erase'),
                          ),
                          IconButton(
                            tooltip: 'Reset puzzle',
                            icon: const Icon(Icons.restart_alt_rounded),
                            onPressed: () async {
                              final reset = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('A fresh start?'),
                                  content: const Text(
                                    'Clear your answers on this puzzle. Your stars stay safe.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Keep playing'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Reset'),
                                    ),
                                  ],
                                ),
                              );
                              if (reset == true && mounted) _edit(game.reset);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        mainAxisExtent: 52,
                        children: List.generate(10, (i) {
                          final n = (i + 1) % 10;
                          return FilledButton.tonal(
                            key: ValueKey('digit-$n'),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.white,
                              foregroundColor: Palette.ink,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(color: Palette.line),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => _edit(() => game.digit(n)),
                            child: Text(
                              '$n',
                              textScaler: TextScaler.noScaling,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _won ? null : _check,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Check my puzzle'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Whole numbers from 0 to ${game.puzzle.maxValue} · No timer',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
