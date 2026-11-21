import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({
    super.key,
    required this.onDone,
    this.firstLaunch = false,
  });
  final VoidCallback onDone;
  final bool firstLaunch;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('A small guide'),
      automaticallyImplyLeading: !firstLaunch,
    ),
    body: SafeArea(
      child: Content(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const CrossMark(size: 64),
            const SizedBox(height: 24),
            Text(
              'A little math.\nA lovely little pause.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Fill the empty tiles to make every equation true. There is no rush, and no limit on trying.',
              style: TextStyle(fontSize: 17, height: 1.5),
            ),
            const SizedBox(height: 28),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '01  FIND THE MISSING NUMBER',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Palette.teal,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: ['3', '+', '?', '=', '7']
                        .map(
                          (s) => Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: s == '?' ? Palette.teal : Palette.mint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                s,
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: s == '?' ? Colors.white : Palette.ink,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap the empty tile, then enter 4 on the number pad.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '02  FOLLOW THE CROSS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Palette.teal,
                    ),
                  ),
                  SizedBox(height: 12),
                  Icon(Icons.alt_route_rounded, size: 40, color: Palette.teal),
                  SizedBox(height: 12),
                  Text(
                    'Read left to right and top to bottom. A tile at a crossing belongs to both equations. Shaded tiles are clues and cannot be changed.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '03  EXPLORE AT YOUR OWN PACE',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Palette.teal,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Use Check when you are ready. Undo and erase are always free. Every finished puzzle earns three stars, regardless of attempts. All answers are whole numbers, including zero.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onDone,
              child: Text(firstLaunch ? 'Let’s play' : 'Back to my puzzles'),
            ),
          ],
        ),
      ),
    ),
  );
}
