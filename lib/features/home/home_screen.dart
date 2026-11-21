import 'package:flutter/material.dart';
import '../collection/collection_screen.dart';
import '../collection/game_mode.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const GameSelectionScreen();
}

// Kept as the Math Cross level-list route for existing callers.
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const ModeHubScreen(mode: GameMode.cross);
}
