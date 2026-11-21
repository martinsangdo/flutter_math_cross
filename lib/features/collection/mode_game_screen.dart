import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ad_placeholders.dart';
import '../../core/theme.dart';
import '../../data/game_store.dart';
import '../puzzle/game_screen.dart';
import 'game_mode.dart';
import 'mode_puzzle.dart';
import 'mode_session.dart';
import 'mode_board.dart';

ModePuzzle _load((GameMode, int, bool, int) request) => request.$3
    ? ModeLevelFactory().endless(request.$1, request.$2, request.$4)
    : ModeLevelFactory().campaign(request.$1, request.$2);

class ModeGameScreen extends ConsumerStatefulWidget {
  const ModeGameScreen({
    super.key,
    required this.mode,
    required this.level,
    this.endless = false,
  });
  final GameMode mode;
  final int level;
  final bool endless;
  @override
  ConsumerState<ModeGameScreen> createState() => _ModeGameScreenState();
}

class _ModeGameScreenState extends ConsumerState<ModeGameScreen> {
  ModeSession? _session;
  final _focus = FocusNode();
  bool _checked = false, _finished = false, _failed = false;
  String _message = 'Take your time. Every clue helps.';
  String get _draftKey =>
      GameStore.draftKey(widget.mode, widget.level, endless: widget.endless);
  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    final store = ref.read(storeProvider);
    try {
      final puzzle = await compute(_load, (
        widget.mode,
        widget.level,
        widget.endless,
        store.seedFor(widget.mode),
      ));
      if (mounted) {
        setState(
          () => _session = ModeSession(puzzle, draft: store.draft(_draftKey)),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
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
    if (_finished || _session == null) return;
    setState(() {
      _checked = false;
      _message = 'Follow the clues. You can always undo.';
      action();
    });
    ref.read(storeProvider).saveDraft(_draftKey, _session!.entries);
    _sound('tap');
  }

  void _select(int id) {
    setState(() => _session!.select(id));
    _focus.requestFocus();
  }

  void _check() {
    if (_session == null || _finished) return;
    if (_session!.solved) {
      _win();
      return;
    }
    setState(() {
      _checked = true;
      _message = widget.mode == GameMode.honeycomb
          ? 'Check the number of hexagons and the total. Any matching path wins.'
          : 'Not quite yet. Fill every blank and check the marked answers.';
    });
    _sound('try_again');
  }

  void _next() {
    if (!widget.endless && widget.level == ModeLevelFactory.levelCount) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ModeGameScreen(
          mode: widget.mode,
          level: widget.level + 1,
          endless: widget.endless,
        ),
      ),
    );
  }

  Future<void> _win() async {
    setState(() => _finished = true);
    ref
        .read(storeProvider)
        .completeMode(widget.mode, widget.level, endless: widget.endless);
    _sound('win');
    final hasNext =
        widget.endless || widget.level < ModeLevelFactory.levelCount;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Beautifully solved!'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: Palette.gold, size: 44),
                    Icon(Icons.star_rounded, color: Palette.gold, size: 48),
                    Icon(Icons.star_rounded, color: Palette.gold, size: 44),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.mode == GameMode.mosaic) ...[
                  Text(
                    'You revealed a ${_session!.puzzle.artName.toLowerCase()}!',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: GridView.count(
                      crossAxisCount: _session!.puzzle.width,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (
                          var i = 0;
                          i < _session!.puzzle.expressions.length;
                          i++
                        )
                          Container(
                            margin: const EdgeInsets.all(1),
                            color: mosaicColors[_session!.puzzle.solution[i]!],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  hasNext
                      ? 'Another discovery in ${widget.mode.title}. Ready for the next one?'
                      : 'All five ${widget.mode.title} levels complete. Try another game or keep exploring in endless play.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'back'),
              child: const Text('Back to levels'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, hasNext ? 'next' : 'endless'),
              child: Text(hasNext ? 'Next puzzle' : 'Play endless'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (result == 'next') {
      _next();
    } else if (result == 'endless') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ModeGameScreen(
            mode: widget.mode,
            level: ref.read(storeProvider).roundFor(widget.mode),
            endless: true,
          ),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _session == null || _finished) {
      return KeyEventResult.ignored;
    }
    if (kIsWeb && event.character == r'$') {
      _next();
      return KeyEventResult.handled;
    }
    final digit = int.tryParse(event.character ?? '');
    if (digit != null && widget.mode.usesNumbers) {
      _edit(() => _session!.digit(digit));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _check();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      _edit(() => _session!.erase());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
        widget.mode != GameMode.honeycomb) {
      setState(() => _session!.next());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.mode.title} · ${widget.endless ? '∞ ' : ''}${widget.level}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [HintButton(advice: widget.mode.rules)],
      ),
      bottomNavigationBar: const BannerPlaceholder(),
      body: SafeArea(
        child: session == null
            ? Center(
                child: _failed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Let’s give this puzzle another try.'),
                          TextButton(
                            onPressed: () {
                              setState(() => _failed = false);
                              _loadGame();
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
                onKeyEvent: _key,
                child: Content(
                  width: 540,
                  child: ListView(
                    key: const ValueKey('mode-game-scroll'),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    children: [
                      Text(
                        widget.mode.chapter(session.puzzle.tier),
                        key: const ValueKey('mode-ready'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(widget.mode.tagline),
                      const SizedBox(height: 20),
                      SurfaceCard(
                        padding: 8,
                        child: ModeBoard(
                          session: session,
                          checked: _checked,
                          onSelect: _select,
                          onHex: (cell) => _edit(() {
                            final message = session.appendHex(cell);
                            if (message != null) _message = message;
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(_message, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: session.canUndo
                                ? () => _edit(session.undo)
                                : null,
                            icon: const Icon(Icons.undo_rounded),
                            label: const Text('Undo'),
                          ),
                          TextButton.icon(
                            onPressed: () => _edit(session.erase),
                            icon: const Icon(Icons.backspace_outlined),
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
                                    'Clear this puzzle’s answers. Your stars stay safe.',
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
                              if (reset == true && mounted) {
                                _edit(session.reset);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (widget.mode.usesNumbers)
                        GridView.count(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          mainAxisExtent: 52,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (var i = 1; i <= 10; i++)
                              FilledButton.tonal(
                                key: ValueKey('mode-digit-${i % 10}'),
                                onPressed: () =>
                                    _edit(() => session.digit(i % 10)),
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  '${i % 10}',
                                  textScaler: TextScaler.noScaling,
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (widget.mode == GameMode.operators)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (var code = 0; code < 4; code++)
                              SizedBox(
                                width: 60,
                                height: 56,
                                child: FilledButton.tonal(
                                  key: ValueKey('choice-$code'),
                                  onPressed: () =>
                                      _edit(() => session.put(code)),
                                  style: FilledButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    const ['+', '−', '×', '÷'][code],
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (widget.mode == GameMode.mosaic)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var code = 0; code < 4; code++)
                              OutlinedButton(
                                key: ValueKey('choice-$code'),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: mosaicColors[code],
                                  foregroundColor: code == 1 || code == 3
                                      ? Colors.white
                                      : Palette.ink,
                                ),
                                onPressed: () => _edit(() => session.put(code)),
                                child: Text(
                                  '${mosaicNames[code]} · ${session.puzzle.palette[code]}',
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _finished ? null : _check,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Check my puzzle'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.mode.usesNumbers
                            ? 'Whole numbers, including zero. No timer.'
                            : 'No timer. Every attempt is a discovery.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
