import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/game_store.dart';
import '../puzzle/game_screen.dart';
import '../puzzle/puzzle.dart';
import '../settings/settings_screen.dart';
import 'game_mode.dart';
import 'mode_board.dart';
import 'mode_game_screen.dart';

Widget gameFor(GameMode mode, int level, {bool endless = false}) =>
    mode == GameMode.cross
    ? GameScreen(level: level, endless: endless)
    : ModeGameScreen(mode: mode, level: level, endless: endless);

void openModeGame(
  BuildContext context,
  GameStore store,
  GameMode mode,
  int level, {
  bool endless = false,
}) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) {
        if (store.guideSeen(mode)) {
          return gameFor(mode, level, endless: endless);
        }
        return ModeGuideScreen(
          mode: mode,
          firstTime: true,
          onDone: () {
            store.finishGuide(mode);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (_) => gameFor(mode, level, endless: endless),
              ),
            );
          },
        );
      },
    ),
  );
}

class GameSelectionScreen extends ConsumerWidget {
  const GameSelectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final completed = GameMode.values.fold<int>(
      0,
      (sum, mode) => sum + store.completedFor(mode),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Math Cross · Puzzle Worlds',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Content(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'NINE WAYS TO WONDER',
                style: TextStyle(
                  color: Palette.teal,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Find your kind\nof puzzle.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Nine little worlds. Five levels each.\nExplore them in any order, at your own pace.',
              ),
              const SizedBox(height: 20),
              SurfaceCard(
                color: Palette.teal,
                padding: 18,
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Palette.gold,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '$completed / ${GameMode.values.length * LevelFactory.campaignCount} puzzles discovered',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              for (final mode in GameMode.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: const BorderSide(color: Palette.line),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('mode-${mode.id}'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ModeHubScreen(mode: mode),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: mode.index.isEven
                                    ? Palette.mint
                                    : Palette.gold.withValues(alpha: .3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                modeIcon(mode),
                                color: Palette.teal,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(mode.tagline),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${store.completedFor(mode)}/${LevelFactory.campaignCount} complete  ·  Endless available',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Palette.teal,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Palette.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (!store.persistent)
                const Text(
                  'Saving is unavailable right now. Keep this session open to retain your progress.',
                ),
              const SizedBox(height: 12),
              const Text(
                'Offline play. No timers. Plenty to discover.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModeHubScreen extends ConsumerWidget {
  const ModeHubScreen({super.key, required this.mode});
  final GameMode mode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final complete = store.completedFor(mode) == LevelFactory.campaignCount;
    return Scaffold(
      appBar: AppBar(
        title: Text(mode.title),
        actions: [
          IconButton(
            tooltip: 'How to play',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => ModeGuideScreen(
                  mode: mode,
                  onDone: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Content(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(modeIcon(mode), size: 52, color: Palette.teal),
              ),
              const SizedBox(height: 20),
              Text(
                mode.tagline,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(mode.rules),
              const SizedBox(height: 24),
              SurfaceCard(
                color: Palette.mint,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete
                          ? 'A whole world, discovered.'
                          : 'Your next discovery',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${store.completedFor(mode)} of ${LevelFactory.campaignCount} complete · ${store.completedFor(mode) * 3} stars',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => openModeGame(
                          context,
                          store,
                          mode,
                          complete ? store.roundFor(mode) : store.nextFor(mode),
                          endless: complete,
                        ),
                        icon: Icon(
                          complete
                              ? Icons.all_inclusive_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          complete
                              ? 'Explore endless play'
                              : 'Play level ${store.nextFor(mode)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'The puzzle path',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (var id = 1; id <= LevelFactory.campaignCount; id++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    onPressed: store.unlockedFor(mode, id)
                        ? () => openModeGame(context, store, mode, id)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            '$id',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              id == 1
                                  ? 'First discovery'
                                  : id == 5
                                  ? 'Final challenge'
                                  : 'Discovery $id',
                            ),
                          ),
                          Icon(
                            store.starsFor(mode, id) > 0
                                ? Icons.star_rounded
                                : store.unlockedFor(mode, id)
                                ? Icons.play_arrow_rounded
                                : Icons.lock_outline_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => openModeGame(
                  context,
                  store,
                  mode,
                  store.roundFor(mode),
                  endless: true,
                ),
                icon: const Icon(Icons.all_inclusive_rounded),
                label: Text('Endless · Round ${store.roundFor(mode)}'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Progress in this world is separate from every other game.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModeGuideScreen extends StatelessWidget {
  const ModeGuideScreen({
    super.key,
    required this.mode,
    required this.onDone,
    this.firstTime = false,
  });
  final GameMode mode;
  final VoidCallback onDone;
  final bool firstTime;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('How to play ${mode.title}')),
    body: SafeArea(
      child: Content(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(modeIcon(mode), size: 80, color: Palette.teal),
            const SizedBox(height: 24),
            Text(
              mode.tagline,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(mode.rules, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            SurfaceCard(
              color: Palette.mint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRY THIS IDEA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Palette.teal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    mode.example,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tap to select. Use Undo if you change your mind. Press Check when you are ready. Every completed puzzle earns three stars—there is no timer.',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onDone,
              child: Text(firstTime ? 'Let’s play ${mode.title}' : 'Got it'),
            ),
          ],
        ),
      ),
    ),
  );
}

class CollectionWelcome extends StatelessWidget {
  const CollectionWelcome({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Welcome, curious mind')),
    body: SafeArea(
      child: Content(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const CrossMark(size: 72),
            const SizedBox(height: 24),
            Text(
              'A little math.\nNine little worlds.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose any game to begin. Each has five levels, a quick guide, and its own saved progress. Endless play keeps the discoveries coming.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final mode in GameMode.values)
                  Chip(
                    avatar: Icon(modeIcon(mode), size: 20),
                    label: Text(mode.title),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const SurfaceCard(
              child: Text(
                'No timers. No lives to lose.\n\nTap a tile to select it. Your game will explain how to fill it. Undo and reset are always free. Finish a puzzle to collect three stars and open the next level in that game.',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onDone, child: const Text('Choose a game')),
          ],
        ),
      ),
    ),
  );
}
